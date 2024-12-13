#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include <mach-o/dyld.h>
#include <mach-o/getsect.h>
#include <string.h>
#include <sys/time.h>
#include "fishhook.h"

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

// hook system gettimeofday and clock_gettime

static float gettimeofday_speed = 1.0;
static float clock_gettime_speed = 1.0;

static time_t pre_sec;
static suseconds_t pre_usec;
static time_t true_pre_sec;
static suseconds_t true_pre_usec;

#define USec_Scale (1000000LL)
#define NSec_Scale (1000000000LL)

static int (*real_gettimeofday)(struct timeval *, void *) = NULL;

int my_gettimeofday(struct timeval *tv, struct timezone *tz) {
    int ret = real_gettimeofday(tv, tz);
    if (!ret) {
        if (!pre_sec) {
            pre_sec = tv->tv_sec;
            true_pre_sec = tv->tv_sec;
            pre_usec = tv->tv_usec;
            true_pre_usec = tv->tv_usec;
        } else {
            int64_t true_curSec = tv->tv_sec * USec_Scale + tv->tv_usec;
            int64_t true_preSec = true_pre_sec * USec_Scale + true_pre_usec;
            int64_t invl = true_curSec - true_preSec;
            invl *= gettimeofday_speed;

            int64_t curSec = pre_sec * USec_Scale + pre_usec;
            curSec += invl;

            time_t used_sec = curSec / USec_Scale;
            suseconds_t used_usec = curSec % USec_Scale;

            true_pre_sec = tv->tv_sec;
            true_pre_usec = tv->tv_usec;
            tv->tv_sec = used_sec;
            tv->tv_usec = used_usec;
            pre_sec = used_sec;
            pre_usec = used_usec;
        }
    }
    return ret;
}

int hook_gettimeofday() {
    if (real_gettimeofday) {
        return 0;
    }
    return rebind_symbols((struct rebinding[1]){{"gettimeofday", my_gettimeofday,
                                                 (void *)&real_gettimeofday}},
                          1);
}

void restore_gettimeofday() { gettimeofday_speed = 1.0; }

void set_gettimeofday(float a1) { gettimeofday_speed = a1; }

static int (*real_clock_gettime)(clockid_t clock_id,
                                 struct timespec *tp) = NULL;

int my_clock_gettime(clockid_t clk_id, struct timespec *tp) {
    int ret = real_clock_gettime(clk_id, tp);
    if (!ret) {
        if (!pre_sec) {
            pre_sec = tp->tv_sec;
            true_pre_sec = tp->tv_sec;
            pre_usec = tp->tv_nsec;
            true_pre_usec = tp->tv_nsec;
        } else {
            int64_t true_curSec = tp->tv_sec * NSec_Scale + tp->tv_nsec;
            int64_t true_preSec = true_pre_sec * NSec_Scale + true_pre_usec;
            int64_t invl = true_curSec - true_preSec;
            invl *= clock_gettime_speed;

            int64_t curSec = pre_sec * NSec_Scale + pre_usec;
            curSec += invl;

            time_t used_sec = curSec / NSec_Scale;
            suseconds_t used_usec = curSec % NSec_Scale;

            true_pre_sec = tp->tv_sec;
            true_pre_usec = tp->tv_nsec;
            tp->tv_sec = used_sec;
            tp->tv_nsec = used_usec;
            pre_sec = used_sec;
            pre_usec = used_usec;
        }
    }
    return ret;
}

int hook_clock_gettime(void) {
    if (real_clock_gettime) {
        return 0;
    }

    return rebind_symbols(
        (struct rebinding[1]){
            {"clock_gettime", my_clock_gettime, (void *)&real_clock_gettime}},
        1);
}

void restore_clock_gettime(void) { clock_gettime_speed = 1.0; }

void set_clock_gettime(float a1) { clock_gettime_speed = a1; }

// UI

@interface WindowView : NSView

@end

@interface WindowView ()

@property(nonatomic, strong) NSView *uiContainer;
@property(nonatomic, assign) NSPoint lastLocation;

typedef NS_ENUM(NSUInteger, SwitchMod) { M1, M2, M3, M4 };

@property(nonatomic, assign) SwitchMod currentMod;

@property(nonatomic, strong) NSButton *button1;
@property(nonatomic, strong) NSButton *button2;
@property(nonatomic, strong) NSButton *button3;
@property(nonatomic, strong) NSButton *button4;
@property(nonatomic, strong) NSButton *button5;

@property(nonatomic, strong) NSArray *speedValues;
@property(nonatomic, assign) NSInteger currentIndex;

+ (id)sharedInstance;
@end

@implementation WindowView

+ (id)sharedInstance {
    static NSView *ui;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        ui = [[self alloc] init];
    });

    return ui;
}

- (instancetype)init {
    NSRect screenRect = [[NSScreen mainScreen] frame];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;

    CGFloat initialH = 52;
    CGFloat initialY = screenHeight / 5;
    CGFloat initialX = screenWidth - initialH * 5;
    CGFloat initialW = initialH * 5;

    self = [super initWithFrame:NSMakeRect(initialX, initialY, initialW, initialH)];

    self.wantsLayer = YES;
    self.layer.backgroundColor = [NSColor.windowBackgroundColor CGColor];
    self.layer.cornerRadius = initialH / 2 - 5;

    NSPanGestureRecognizer *panGesture = [[NSPanGestureRecognizer alloc]
        initWithTarget:self
                action:@selector(handlePanGesture:)];
    [self addGestureRecognizer:panGesture];

    self.uiContainer = [[NSView alloc] initWithFrame:self.bounds];
    [self addSubview:self.uiContainer];

    self.currentMod = M1;

    self.speedValues = @[
        @0.1, @0.25, @0.5, @0.75, @0.9, @1,   @1.1, @1.2, @1.3, @1.4, @1.5, @1.6,
        @1.7, @1.8,  @1.9, @2,    @2.1, @2.2, @2.3, @2.4, @2.5, @5,   @10,  @20,
        @30,  @40,   @50,  @60,   @70,  @80,  @90,  @100, @200, @500, @1000
    ];

    self.currentIndex = 5;

    [self setupButtons];

    return self;
}

- (void)setupButtons {
    CGFloat buttonWidth = self.bounds.size.height;

    // Button 1
    self.button1 = [NSButton buttonWithTitle:@"♥" target:self action:@selector(Button1Changed)];
    self.button1.frame = NSMakeRect(0, 0, buttonWidth, buttonWidth);
    self.button1.bezelStyle = NSBezelStyleRounded;
    [self.uiContainer addSubview:self.button1];

    // Button 2 - Previous
    self.button2 = [NSButton buttonWithTitle:@"◀" target:self action:@selector(Button2Changed)];
    self.button2.frame = NSMakeRect(buttonWidth, 0, buttonWidth, buttonWidth);
    self.button2.bezelStyle = NSBezelStyleRounded;
    [self.uiContainer addSubview:self.button2];

    // Button 3 - Speed Display
    self.button3 = [NSButton buttonWithTitle:[self.speedValues[self.currentIndex] stringValue] 
                                       target:self 
                                       action:@selector(Button3Changed)];
    self.button3.frame = NSMakeRect(2 * buttonWidth, 0, buttonWidth, buttonWidth);
    self.button3.bezelStyle = NSBezelStyleRounded;
    [self.uiContainer addSubview:self.button3];

    //
