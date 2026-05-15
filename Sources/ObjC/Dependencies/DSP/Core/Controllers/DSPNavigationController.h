#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DSPNavigationController : UINavigationController

+ (instancetype)withRootViewController:(UIViewController *)rootVC;

@end

@interface UINavigationController (DSPObjectExploring)

/// Push an object explorer view controller onto the navigation stack
- (void)pushExplorerForObject:(id)object;
/// Push an object explorer view controller onto the navigation stack
- (void)pushExplorerForObject:(id)object animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
