#import "DSPWindow.h"
#import "DSPUtility.h"
#import <objc/runtime.h>

@implementation DSPWindow

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Some apps have windows at UIWindowLevelStatusBar + n.
        // If we make the window level too high, we block out UIAlertViews.
        // There's a balance between staying above the app's windows and staying below alerts.
        self.windowLevel = UIWindowLevelAlert - 1;
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return [self.eventDelegate shouldHandleTouchAtPoint:point];
}

- (BOOL)shouldAffectStatusBarAppearance {
    return [self isKeyWindow];
}

- (BOOL)canBecomeKeyWindow {
    return [self.eventDelegate canBecomeKeyWindow];
}

- (void)makeKeyWindow {
    _previousKeyWindow = DSPUtility.appKeyWindow;
    [super makeKeyWindow];
}

- (void)resignKeyWindow {
    [super resignKeyWindow];
    _previousKeyWindow = nil;
}

+ (void)initialize {
    // This adds a method (superclass override) at runtime which gives us the status bar behavior we want.
    // The DSP window is intended to be an overlay that generally doesn't affect the app underneath.
    // Most of the time, we want the app's main window(s) to be in control of status bar behavior.
    // Done at runtime with an obfuscated selector because it is private API. But you shouldn't ship this to the App Store anyways...
    NSString *canAffectSelectorString = [@[@"_can", @"Affect", @"Status", @"Bar", @"Appearance"] componentsJoinedByString:@""];
    SEL canAffectSelector = NSSelectorFromString(canAffectSelectorString);
    Method shouldAffectMethod = class_getInstanceMethod(self, @selector(shouldAffectStatusBarAppearance));
    IMP canAffectImplementation = method_getImplementation(shouldAffectMethod);
    class_addMethod(self, canAffectSelector, canAffectImplementation, method_getTypeEncoding(shouldAffectMethod));

    // One more...
    NSString *canBecomeKeySelectorString = [NSString stringWithFormat:@"_%@", NSStringFromSelector(@selector(canBecomeKeyWindow))];
    SEL canBecomeKeySelector = NSSelectorFromString(canBecomeKeySelectorString);
    Method canBecomeKeyMethod = class_getInstanceMethod(self, @selector(canBecomeKeyWindow));
    IMP canBecomeKeyImplementation = method_getImplementation(canBecomeKeyMethod);
    class_addMethod(self, canBecomeKeySelector, canBecomeKeyImplementation, method_getTypeEncoding(canBecomeKeyMethod));
}

@end
