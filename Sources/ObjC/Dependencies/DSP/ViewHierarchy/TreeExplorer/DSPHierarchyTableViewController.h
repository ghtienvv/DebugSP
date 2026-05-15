#import "DSPTableViewController.h"

@interface DSPHierarchyTableViewController : DSPTableViewController

+ (instancetype)windows:(NSArray<UIWindow *> *)allWindows
             viewsAtTap:(NSArray<UIView *> *)viewsAtTap
           selectedView:(UIView *)selectedView;

@property (nonatomic) UIView *selectedView;
@property (nonatomic) void(^didSelectRowAction)(UIView *selectedView);

@end
