#import "DSPTableViewController.h"
#import "States/Globals/DSPGlobalsEntry.h"
#import "DSPFileBrowserSearchOperation.h"

@interface DSPFileBrowserController : DSPTableViewController <DSPGlobalsEntry>

+ (instancetype)path:(NSString *)path;
- (id)initWithPath:(NSString *)path;

@end
