#import "DSPFilteringTableViewController.h"

@interface DSPObjectListViewController : DSPFilteringTableViewController

/// This will either return a list of the instances, or take you straight
/// to the explorer itself if there is only one instance.
+ (UIViewController *)instancesOfClassWithName:(NSString *)className retained:(BOOL)retain;
+ (instancetype)subclassesOfClassWithName:(NSString *)className;
+ (instancetype)objectsWithReferencesToObject:(id)object retained:(BOOL)retain;

@end
