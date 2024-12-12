#import <Cocoa/Cocoa.h>

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
    static WindowView *ui;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        ui = [[self alloc] init];
    });

    return ui;
}

- (instancetype)init {
    CGFloat screenWidth = [NSScreen mainScreen].frame.size.width;
    CGFloat screenHeight = [NSScreen mainScreen].frame.size.height;

    CGFloat initialH = 50.0;
    CGFloat initialY = screenHeight / 5;
    CGFloat initialX = screenWidth - initialH * 5;
    CGFloat initialW = initialH * 5;

    self = [super initWithFrame:NSMakeRect(initialX, initialY, initialW, initialH)];
    if (!self) {
        return nil;
    }

    self.wantsLayer = YES;
    self.layer.backgroundColor = NSColor.windowBackgroundColor.CGColor;
    self.layer.cornerRadius = initialH / 2 - 5;

    self.uiContainer = [[NSView alloc] initWithFrame:self.bounds];
    [self addSubview:self.uiContainer];

    self.currentMod = M1;
    self.speedValues = @[
        @0.1, @0.25, @0.5, @0.75, @0.9, @1, @1.1, @1.2, @1.3, @1.4, @1.5, @1.6,
        @1.7, @1.8, @1.9, @2, @2.1, @2.2, @2.3, @2.4, @2.5, @5, @10, @20, @30, @40,
        @50, @60, @70, @80, @90, @100, @200, @500, @1000
    ];

    self.currentIndex = 5;

    [self setupButtons];

    return self;
}

- (void)setupButtons {
    CGFloat buttonWidth = self.bounds.size.height;

    self.button1 = [self createButtonWithTitle:@"❤️" action:@selector(Button1Changed)];
    self.button1.frame = NSMakeRect(0, 0, buttonWidth, buttonWidth);
    [self.uiContainer addSubview:self.button1];

    self.button2 = [self createButtonWithTitle:@"⏪" action:@selector(Button2Changed)];
    self.button2.frame = NSMakeRect(buttonWidth, 0, buttonWidth, buttonWidth);
    [self.uiContainer addSubview:self.button2];

    self.button3 = [self createButtonWithTitle:self.speedValues[self.currentIndex].stringValue action:@selector(Button3Changed)];
    self.button3.frame = NSMakeRect(2 * buttonWidth, 0, buttonWidth, buttonWidth);
    [self.uiContainer addSubview:self.button3];

    self.button4 = [self createButtonWithTitle:@"⏩" action:@selector(Button4Changed)];
    self.button4.frame = NSMakeRect(3 * buttonWidth, 0, buttonWidth, buttonWidth);
    [self.uiContainer addSubview:self.button4];

    self.button5 = [self createButtonWithTitle:@"▶️" action:@selector(Button5Changed)];
    self.button5.frame = NSMakeRect(4 * buttonWidth, 0, buttonWidth, buttonWidth);
    [self.uiContainer addSubview:self.button5];
}

- (NSButton *)createButtonWithTitle:(NSString *)title action:(SEL)action {
    NSButton *button = [NSButton buttonWithTitle:title target:self action:action];
    button.bezelStyle = NSBezelStyleRegularSquare;
    button.wantsLayer = YES;
    button.layer.backgroundColor = NSColor.windowBackgroundColor.CGColor;
    button.layer.cornerRadius = 5;
    return button;
}

- (void)mouseDown:(NSEvent *)event {
    self.lastLocation = [event locationInWindow];
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint currentLocation = [event locationInWindow];
    CGFloat deltaX = currentLocation.x - self.lastLocation.x;
    CGFloat deltaY = currentLocation.y - self.lastLocation.y;

    NSPoint newOrigin = NSMakePoint(self.frame.origin.x + deltaX, self.frame.origin.y + deltaY);

    // Ensure the window stays within screen bounds
    CGFloat maxX = [NSScreen mainScreen].frame.size.width - self.frame.size.width;
    CGFloat maxY = [NSScreen mainScreen].frame.size.height - self.frame.size.height;

    newOrigin.x = MAX(0, MIN(maxX, newOrigin.x));
    newOrigin.y = MAX(0, MIN(maxY, newOrigin.y));

    [self setFrameOrigin:newOrigin];
    self.lastLocation = currentLocation;
}

- (void)Button1Changed {
    NSString *stateSymbol;
    switch (self.currentMod) {
        case M1:
            stateSymbol = @"♠️";
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
            stateSymbol = @"❤️";
            self.currentMod = M1;
            break;
    }
    [self.button1 setTitle:stateSymbol];
}

- (void)Button2Changed {
    if (self.currentIndex > 0) {
        self.currentIndex--;
        [self updateSpeed];
    }
}

- (void)Button3Changed {
    // TODO: Implement logic for button 3
}

- (void)Button4Changed {
    if (self.currentIndex < self.speedValues.count - 1) {
        self.currentIndex++;
        [self updateSpeed];
    }
}

- (void)Button5Changed {
    // TODO: Implement play/pause functionality
}

- (void)updateSpeed {
    [self.button3 setTitle:self.speedValues[self.currentIndex].stringValue];
}

@end
