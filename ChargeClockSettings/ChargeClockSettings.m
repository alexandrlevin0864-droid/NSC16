#import <Preferences/PSListController.h>

@interface ChargeClockSettingsController : PSListController
@end

@implementation ChargeClockSettingsController
- (id)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }
    return _specifiers;
}
@end