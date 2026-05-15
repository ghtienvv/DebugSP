#import <UIKit/UIKit.h>

@class DSPNetworkTransaction;

@interface DSPNetworkTransactionCell : UITableViewCell

@property (nonatomic) DSPNetworkTransaction *transaction;

@property (nonatomic, readonly, class) NSString *reuseID;
@property (nonatomic, readonly, class) CGFloat preferredCellHeight;

@end
