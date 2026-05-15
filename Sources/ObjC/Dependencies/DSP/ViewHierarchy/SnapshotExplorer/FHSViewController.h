#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// The view controller
/// "FHS" stands for "DSP (view) hierarchy snapshot"
@interface FHSViewController : UIViewController

/// Use this when you want to snapshot a set of windows.
+ (instancetype)snapshotWindows:(NSArray<UIWindow *> *)windows;
/// Use this when you want to snapshot a specific slice of the view hierarchy.
+ (instancetype)snapshotView:(UIView *)view;
/// Use this when you want to emphasize specific views on the screen.
/// These views must all be in the same window as the selected view.
+ (instancetype)snapshotViewsAtTap:(NSArray<UIView *> *)viewsAtTap selectedView:(UIView *)view;

@property (nonatomic, nullable) UIView *selectedView;

@end

NS_ASSUME_NONNULL_END
