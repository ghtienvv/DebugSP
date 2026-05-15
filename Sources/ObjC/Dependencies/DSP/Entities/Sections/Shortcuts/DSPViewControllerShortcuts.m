#import "DSPViewControllerShortcuts.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPRuntimeUtility.h"
#import "DSPShortcut.h"
#import "DSPAlert.h"

@interface DSPViewControllerShortcuts ()
@end

@implementation DSPViewControllerShortcuts

#pragma mark - Overrides

+ (instancetype)forObject:(UIViewController *)viewController {
    BOOL (^vcIsInuse)(UIViewController *) = ^BOOL(UIViewController *controller) {
        if (controller.viewIfLoaded.window) {
            return YES;
        }

        return controller.navigationController != nil;
    };
    
    return [self forObject:viewController additionalRows:@[
        [DSPActionShortcut title:@"Push View Controller"
            subtitle:^NSString *(UIViewController *controller) {
                return vcIsInuse(controller) ? @"In use, cannot push" : nil;
            }
            selectionHandler:^void(UIViewController *host, UIViewController *controller) {
                if (!vcIsInuse(controller)) {
                    [host.navigationController pushViewController:controller animated:YES];
                } else {
                    [DSPAlert
                        showAlert:@"Cannot Push View Controller"
                        message:@"This view controller's view is currently in use."
                        from:host
                    ];
                }
            }
            accessoryType:^UITableViewCellAccessoryType(UIViewController *controller) {
                if (!vcIsInuse(controller)) {
                    return UITableViewCellAccessoryDisclosureIndicator;
                } else {
                    return UITableViewCellAccessoryNone;
                }
            }
        ]
    ]];
}

@end
