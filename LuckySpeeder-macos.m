/*

MIT License

Copyright (c) 2024 kekeimiku
Copyright (c) 2024 ac0d3r

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

#include "fishhook.h"
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <string.h>
#include <sys/time.h>

// hook unity timeScale

static float timeScale_speed = 1.0;

static void (*real_timeScale)(float) = NULL;

void my_timeScale() {
  if (real_timeScale) {
    real_timeScale(timeScale_speed);
  }
}

int hook_timeScale() {
  if (real_timeScale) {
    return 0;
  }

  intptr_t unity_vmaddr_slide = 0;
  uint32_t image_count = _dyld_image_count();
  const char *image_name;
  for (uint32_t i = 0; i < image_count; ++i) {
    image_name = _dyld_get_image_name(i);
    if (strstr(image_name, "UnityFramework.framework/UnityFramework")) {
      unity_vmaddr_slide = _dyld_get_image_vmaddr_slide(i);
      break;
    }
  }
  if (!unity_vmaddr_slide)
    return -1;

  size_t size;

  uint8_t *cstring_section_data =
      getsectiondata((const struct mach_header_64 *)unity_vmaddr_slide,
                     "__TEXT", "__cstring", &size);
  if (!cstring_section_data)
    return -1;

  uint8_t *time_scale_function_address =
      memmem(cstring_section_data, size,
             "UnityEngine.Time::set_timeScale(System.Single)", 0x2F);
  if (!time_scale_function_address)
    return -1;

  uintptr_t il2cpp_section_base = (uintptr_t)getsectiondata(
      (const struct mach_header_64 *)unity_vmaddr_slide, "__TEXT", "il2cpp",
      &size);
  if (!il2cpp_section_base)
    return -1;

  uint8_t *il2cpp_end = (uint8_t *)(size + il2cpp_section_base);
  if (il2cpp_section_base + 4 >= size + il2cpp_section_base)
    return -1;

  uintptr_t first_instruction = *(uint32_t *)il2cpp_section_base;
  uintptr_t resolved_address, function_offset, second_instruction;

  while (1) {
    second_instruction = *(uint32_t *)(il2cpp_section_base + 4);
    if ((first_instruction & 0x9F000000) == 0x90000000 &&
        (second_instruction & 0xFF800000) == 0x91000000) {
      resolved_address = (il2cpp_section_base & 0xFFFFFFFFFFFFF000LL) +
                         (int32_t)(((first_instruction >> 3) & 0xFFFFFFFC |
                                    (first_instruction >> 29) & 3)
                                   << 12);
      function_offset = (second_instruction >> 10) & 0xFFF;
      if ((second_instruction & 0xC00000) != 0)
        function_offset <<= 12;
      if ((uint8_t *)(resolved_address + function_offset) ==
          time_scale_function_address)
        break;
    }
    il2cpp_section_base += 4;
    first_instruction = second_instruction;
    if ((uint8_t *)(il2cpp_section_base + 8) >= il2cpp_end)
      return -1;
  }

  uintptr_t current_address = il2cpp_section_base;
  uintptr_t current_instruction, code_section_address;

  do {
    current_instruction = *(uint32_t *)(current_address - 4);
    current_address -= 4;
  } while ((current_instruction & 0x9F000000) != 0x90000000);

  code_section_address = (current_address & 0xFFFFFFFFFFFFF000LL) +
                         (int32_t)(((current_instruction >> 3) & 0xFFFFFFFC |
                                    (current_instruction >> 29) & 3)
                                   << 12);

  uintptr_t method_data = *(uint32_t *)(current_address + 4);
  uintptr_t function_data_offset;

  if ((method_data & 0x1000000) != 0)
    function_data_offset = 8 * ((method_data >> 10) & 0xFFF);
  else
    function_data_offset = (method_data >> 10) & 0xFFF;

  if (*(uintptr_t *)(code_section_address + function_data_offset)) {
    real_timeScale =
        *(void (**)(float))(function_data_offset + code_section_address);
  } else {
    uint32_t instruction_operand = *(uint32_t *)(il2cpp_section_base + 8);
    uint8_t *code_section_start = (uint8_t *)(il2cpp_section_base + 8);
    uintptr_t instruction_offset = (4 * instruction_operand) & 0xFFFFFFC;
    uintptr_t address_offset =
        (4 * (instruction_operand & 0x3FFFFFF)) | 0xFFFFFFFFF0000000LL;

    if (((4 * instruction_operand) & 0x8000000) != 0)
      function_offset = address_offset;
    else
      function_offset = instruction_offset;

    real_timeScale = (void (*)(float))((uintptr_t(*)(void *)) &
                                       code_section_start[function_offset])(
        time_scale_function_address);
  }

  if (real_timeScale) {
    *(uintptr_t *)(function_data_offset + code_section_address) =
        (uintptr_t)my_timeScale;
    return 0;
  }

  return -1;
}

void set_timeScale(float a1) {
  timeScale_speed = a1;
  my_timeScale();
}

void restore_timeScale() { set_timeScale(1.0); }

- (void)initHook {
  hook_timeScale();
  set_timeScale(10.0);
}

@interface AppInitializer : NSObject
+ (void)waitForAppToLoad:(void (^)(void))completionHandler;
@end

@implementation AppInitializer

+ (void)waitForAppToLoad:(void (^)(void))completionHandler {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimer *checkTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                               repeats:YES
                                                                 block:^(NSTimer * _Nonnull timer) {
            // Comprehensive checks for app readiness
            if ([NSApp isRunning] && 
                [NSApp keyWindow] && 
                [[NSApp windows] count] > 0) {
                
                // Stop the timer
                [timer invalidate];
                
                // Run the completion handler
                if (completionHandler) {
                    completionHandler();
                }
            }
        }];
    });
}

@end

// Constructor to run when dylib is loaded
__attribute__((constructor)) static void initialize(void) {
    @autoreleasepool {
        // Wait for app to load and then run custom code
        [AppInitializer waitForAppToLoad:^{
           [self initHook];
        }];
    }
}
