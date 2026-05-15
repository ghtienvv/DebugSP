#import "DSPFilteringTableViewController.h"

@interface DSPTableListViewController : DSPFilteringTableViewController

+ (BOOL)supportsExtension:(NSString *)extension;
- (instancetype)initWithPath:(NSString *)path;

@end
