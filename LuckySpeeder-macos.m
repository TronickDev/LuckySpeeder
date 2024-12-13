#include "fishhook.h"
#import <AppKit/AppKit.h>
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import <string.h>
#import <sys/time.h>

// hook unity timeScale

static float timeScale_speed = 1.0;

static void (*real_timeScale)(float) = NULL;

void my_timeScale() {
  if (real_timeScale) {
    real_timeScale(timeScale_speed);
  }
}

// ... Der Rest des Skripts für das Hooking bleibt unverändert ...

// UI für macOS

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
  CGFloat screenWidth = [NSScreen mainScreen].frame.size.width;
  CGFloat screenHeight = [NSScreen mainScreen].frame.size.height;

  CGFloat initialH = 32; // macOS spezifische Höhe
  CGFloat initialY = screenHeight / 5;
  CGFloat initialX = screenWidth - initialH * 5;
  CGFloat initialW = initialH * 5;

  self = [super initWithFrame:NSMakeRect(initialX, initialY, initialW, initialH)];

  CGFloat buttonWidth = self.bounds.size.height;

  self.backgroundColor = [NSColor windowBackgroundColor];
  self.layer.cornerRadius = buttonWidth / 2 - 5;
  self.layer.shadowOpacity = 0.5;

  self.uiContainer = [[NSView alloc] initWithFrame:self.bounds];
  [self addSubview:self.uiContainer];

  self.currentMod = M1;

  self.speedValues = @[
    @0.1, @0.25, @0.5, @0.75, @0.9, @1, @1.1, @1.2, @1.3, @1.4, @1.5, @1.6,
    @1.7, @1.8, @1.9, @2, @2.1, @2.2, @2.3, @2.4, @2.5, @5, @10, @20, @30,
    @40, @50, @60, @70, @80, @90, @100, @200, @500, @1000
  ];

  self.currentIndex = 5;

  self.button1 = [NSButton buttonWithTitle:@"" target:self action:@selector(Button1Changed)];
  self.button1.frame = NSMakeRect(0, 0, buttonWidth, buttonWidth);
  [self.button1 setBezelStyle:NSBezelStyleRegularSquare];
  [self.uiContainer addSubview:self.button1];

  self.button2 = [NSButton buttonWithTitle:@"" target:self action:@selector(Button2Changed)];
  self.button2.frame = NSMakeRect(buttonWidth, 0, buttonWidth, buttonWidth);
  [self.button2 setBezelStyle:NSBezelStyleRegularSquare];
  [self.uiContainer addSubview:self.button2];

  self.button3 = [NSButton buttonWithTitle:[self.speedValues[self.currentIndex] stringValue] target:self action:@selector(Button3Changed)];
  self.button3.frame = NSMakeRect(2 * buttonWidth, 0, buttonWidth, buttonWidth);
  [self.button3 setBezelStyle:NSBezelStyleRegularSquare];
  [self.uiContainer addSubview:self.button3];

  self.button4 = [NSButton buttonWithTitle:@"" target:self action:@selector(Button4Changed)];
  self.button4.frame = NSMakeRect(3 * buttonWidth, 0, buttonWidth, buttonWidth);
  [self.button4 setBezelStyle:NSBezelStyleRegularSquare];
  [self.uiContainer addSubview:self.button4];

  self.button5 = [NSButton buttonWithTitle:@"" target:self action:@selector(Button5Changed)];
  self.button5.frame = NSMakeRect(4 * buttonWidth, 0, buttonWidth, buttonWidth);
  [self.button5 setBezelStyle:NSBezelStyleRegularSquare];
  [self.uiContainer addSubview:self.button5];

  return self;
}

- (void)Button1Changed {
  self.userInteractionEnabled = NO;

  NSString *stateSymbol = @"";
  switch (self.currentMod) {
  case M1:
    stateSymbol = @"♥️";
    self.currentMod = M2;
    break;
  case M2:
    stateSymbol = @"♣️";
    self.currentMod = M3;
    break;
  case M3:
    stateSymbol = @"♦️";
    self.currentMod = M4;
    break;
  case M4:
    stateSymbol = @"♠️";
    self.currentMod = M1;
    break;
  }

  [self.button1 setTitle:stateSymbol];
  self.userInteractionEnabled = YES;
}

- (void)Button2Changed {
  if (self.currentIndex > 0) {
    self.currentIndex--;
    [self.button3 setTitle:[self.speedValues[self.currentIndex] stringValue]];
  }
}

- (void)Button3Changed {
  // TODO
}

- (void)Button4Changed {
  if (self.currentIndex < self.speedValues.count - 1) {
    self.currentIndex++;
    [self.button3 setTitle:[self.speedValues[self.currentIndex] stringValue]];
  }
}

- (void)Button5Changed {
  // Hier die Logik für Button5 anpassen
}

@end
