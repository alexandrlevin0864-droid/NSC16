#import <UIKit/UIKit.h>

#define kPrefsID    "com.example.nsc16"
#define kPrefsPath  "/var/mobile/Library/Preferences/com.example.nsc16.plist"

static NSDictionary *CCPrefs(void) {
    CFPreferencesSynchronize(CFSTR(kPrefsID), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:@(kPrefsPath)];
    return d ?: @{};
}
static BOOL CCBool(NSString *key, BOOL def) {
    id v = CCPrefs()[key];
    return v ? [v boolValue] : def;
}
static CGFloat CCFloat(NSString *key, CGFloat def) {
    id v = CCPrefs()[key];
    return v ? [v floatValue] : def;
}

/* ================= Core ================= */
@interface NSC16Controller : UIViewController
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, strong) UILabel *infoLabel;
@property (nonatomic, strong) UIProgressView *batteryBar;
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) NSTimer *ticker;
@property (nonatomic, strong) NSDateFormatter *timeFmt;
@property (nonatomic, strong) NSDateFormatter *dateFmt;
@property (nonatomic, assign) BOOL active;
@end

@implementation NSC16Controller

+ (instancetype)shared {
    static NSC16Controller *s = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [NSC16Controller new]; });
    return s;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    self.timeFmt = [NSDateFormatter new];
    self.timeFmt.locale = [NSLocale currentLocale];
    self.dateFmt = [NSDateFormatter new];
    self.dateFmt.locale = [NSLocale currentLocale];

    _timeLabel = [UILabel new];
    _timeLabel.textColor = [UIColor whiteColor];
    _timeLabel.textAlignment = NSTextAlignmentCenter;
    _timeLabel.font = [UIFont monospacedDigitSystemFontOfSize:110 weight:UIFontWeightLight];
    _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_timeLabel];

    _infoLabel = [UILabel new];
    _infoLabel.textColor = [UIColor colorWithWhite:0.65 alpha:1];
    _infoLabel.textAlignment = NSTextAlignmentCenter;
    _infoLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightRegular];
    _infoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_infoLabel];

    _batteryBar = [UIProgressView new];
    _batteryBar.progressTintColor = [UIColor systemGreenColor];
    _batteryBar.trackTintColor = [UIColor colorWithWhite:0.22 alpha:1];
    _batteryBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_batteryBar];

    [NSLayoutConstraint activateConstraints:@[
        [_timeLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_timeLabel.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor constant:-20],
        [_infoLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_infoLabel.topAnchor constraintEqualToAnchor:_timeLabel.bottomAnchor constant:18],
        [_batteryBar.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_batteryBar.topAnchor constraintEqualToAnchor:_infoLabel.bottomAnchor constant:22],
        [_batteryBar.widthAnchor constraintEqualToConstant:220],
        [_batteryBar.heightAnchor constraintEqualToConstant:6]
    ]];
}

/* ---------- активация / деактивация ---------- */
- (void)activate {
    if (self.active) return;
    self.active = YES;

    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    if (!self.window) {
        self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.window.windowLevel = 1500.0;
        self.window.backgroundColor = [UIColor blackColor];
        self.window.userInteractionEnabled = NO;
        self.window.rootViewController = self;
        self.window.hidden = NO;
    }

    [self applyBrightness];
    [self updateAll];
    self.ticker = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                   target:self
                                                 selector:@selector(tick:)
                                                 userInfo:nil
                                                  repeats:YES];
    if (CCBool(@"NSC16PixelShift", YES)) {
        [self scheduleShift];
    }
}

- (void)deactivate {
    if (!self.active) return;
    self.active = NO;

    [self.ticker invalidate]; self.ticker = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(shift) object:nil];
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    self.window.hidden = YES;
    self.window = nil;
}

/* ---------- обновление ---------- */
- (void)tick:(NSTimer *)t {
    if (!self.active) return;
    [self updateAll];
}

- (void)updateAll {
    NSDate *now = [NSDate date];

    self.timeFmt.dateFormat = CCBool(@"NSC1624h", YES) ? @"HH:mm" : @"h:mm a";
    NSString *time = [self.timeFmt stringFromDate:now];
    if (CCBool(@"NSC16ShowSeconds", YES)) {
        self.timeFmt.dateFormat = [self.timeFmt.dateFormat stringByAppendingString:@":ss"];
        time = [self.timeFmt stringFromDate:now];
    }
    self.timeLabel.text = time;

    NSMutableArray *parts = [NSMutableArray array];
    if (CCBool(@"NSC16ShowDate", YES)) {
        self.dateFmt.dateFormat = @"EEEE, MMMM d";
        [parts addObject:[self.dateFmt stringFromDate:now]];
    }
    if (CCBool(@"NSC16ShowBattery", YES)) {
        CGFloat lvl = [UIDevice currentDevice].batteryLevel;
        [parts addObject:[NSString stringWithFormat:@"%d%%", (int)(lvl * 100)]];
    }
    self.infoLabel.text = [parts componentsJoinedByString:@"  ·  "];

    self.batteryBar.hidden = !CCBool(@"NSC16ShowBattery", YES);
    if (!self.batteryBar.hidden) {
        self.batteryBar.progress = [UIDevice currentDevice].batteryLevel;
    }
}

- (void)applyBrightness {
    CGFloat b = CCFloat(@"NSC16Brightness", 0.5);
    [[UIScreen mainScreen] setBrightness:b];
}

/* ---------- пиксель-шифтинг ---------- */
- (void)scheduleShift {
    [self performSelector:@selector(shift) withObject:nil afterDelay:8.0];
}

- (void)shift {
    if (!self.active || !CCBool(@"NSC16PixelShift", YES)) return;
    NSInteger ox = (NSInteger)(arc4random_uniform(21)) - 10;
    NSInteger oy = (NSInteger)(arc4random_uniform(21)) - 10;
    [UIView animateWithDuration:1.0 animations:^{
        self.timeLabel.transform = CGAffineTransformMakeTranslation(ox, oy);
        self.infoLabel.transform = CGAffineTransformMakeTranslation(-ox, -oy);
        self.batteryBar.transform = CGAffineTransformMakeTranslation(ox * 0.6, oy * 0.6);
    } completion:^(BOOL finished) {
        [self scheduleShift];
    }];
}

/* ---------- слушатель батареи ---------- */
- (void)batteryStateChanged {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!CCBool(@"NSC16Enabled", YES)) { [self deactivate]; return; }
        UIDeviceBatteryState st = [UIDevice currentDevice].batteryState;
        if (st == UIDeviceBatteryStateCharging || st == UIDeviceBatteryStateFull) {
            [self activate];
        } else {
            [self deactivate];
        }
    });
}

@end

/* ================= САМОЗАПУСК ================= */
%ctor {
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [[NSNotificationCenter defaultCenter]
        addObserver:[NSC16Controller shared]
           selector:@selector(batteryStateChanged)
               name:UIDeviceBatteryStateDidChangeNotification
             object:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSC16Controller shared] batteryStateChanged];
    });
}