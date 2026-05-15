#import "DSPClassShortcuts.h"
#import "DSPShortcut.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPObjectListViewController.h"
#import "NSObject+DSP_Reflection.h"

@interface DSPClassShortcuts ()
@property (nonatomic, readonly) Class cls;
@end

@implementation DSPClassShortcuts

+ (instancetype)forObject:(Class)cls {
    // These additional rows will appear at the beginning of the shortcuts section.
    // The methods below are written in such a way that they will not interfere
    // with properties/etc being registered alongside these
    return [self forObject:cls additionalRows:@[
        [DSPActionShortcut title:@"Find Live Instances" subtitle:nil
            viewer:^UIViewController *(id obj) {
                return [DSPObjectListViewController
                    instancesOfClassWithName:NSStringFromClass(obj)
                    retained:NO
                ];
            }
            accessoryType:^UITableViewCellAccessoryType(id obj) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
        [DSPActionShortcut title:@"List Subclasses" subtitle:nil
            viewer:^UIViewController *(id obj) {
                NSString *name = NSStringFromClass(obj);
                return [DSPObjectListViewController subclassesOfClassWithName:name];
            }
            accessoryType:^UITableViewCellAccessoryType(id view) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
        [DSPActionShortcut title:@"Explore Bundle for Class"
            subtitle:^NSString *(id obj) {
                return [self shortNameForBundlePath:[NSBundle bundleForClass:obj].executablePath];
            }
            viewer:^UIViewController *(id obj) {
                NSBundle *bundle = [NSBundle bundleForClass:obj];
                return [DSPObjectExplorerFactory explorerViewControllerForObject:bundle];
            }
            accessoryType:^UITableViewCellAccessoryType(id view) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
    ]];
}

+ (NSString *)shortNameForBundlePath:(NSString *)imageName {
    NSArray<NSString *> *components = [imageName componentsSeparatedByString:@"/"];
    if (components.count >= 2) {
        return [NSString stringWithFormat:@"%@/%@",
            components[components.count - 2],
            components[components.count - 1]
        ];
    }

    return imageName.lastPathComponent;
}

@end
