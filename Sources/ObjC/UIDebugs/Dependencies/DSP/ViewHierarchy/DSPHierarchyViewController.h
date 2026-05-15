#import "DSPNavigationController.h"

@protocol DSPHierarchyDelegate <NSObject>
- (void)viewHierarchyDidDismiss:(UIView *)selectedView;
@end

/// A navigation controller which manages two child view controllers:
/// a 3D Reveal-like hierarchy explorer, and a 2D tree-list hierarchy explorer.
@interface DSPHierarchyViewController : DSPNavigationController

+ (instancetype)delegate:(id<DSPHierarchyDelegate>)delegate;
+ (instancetype)delegate:(id<DSPHierarchyDelegate>)delegate
              viewsAtTap:(NSArray<UIView *> *)viewsAtTap
            selectedView:(UIView *)selectedView;

- (void)toggleHierarchyMode;

@end
