#import <UIKit/UIKit.h>

@protocol DSPWindowEventDelegate <NSObject>

- (BOOL)shouldHandleTouchAtPoint:(CGPoint)pointInWindow;
- (BOOL)canBecomeKeyWindow;

@end

#pragma mark -
@interface DSPWindow : UIWindow

@property (nonatomic, weak) id <DSPWindowEventDelegate> eventDelegate;

/// Tracked so we can restore the key window after dismissing a modal.
/// We need to become key after modal presentation so we can correctly capture input.
/// If we're just showing the toolbar, we want the main app's window to remain key
/// so that we don't interfere with input, status bar, etc.
@property (nonatomic, readonly) UIWindow *previousKeyWindow;

@end
