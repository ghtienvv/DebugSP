#import <UIKit/UIKit.h>

@class DSPHTTPTransaction;

@interface DSPHTTPTransactionDetailController : UITableViewController

+ (instancetype)withTransaction:(DSPHTTPTransaction *)transaction;

@end
