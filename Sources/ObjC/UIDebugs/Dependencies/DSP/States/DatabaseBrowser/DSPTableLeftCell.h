#import <UIKit/UIKit.h>

@interface DSPTableLeftViewCell : UITableViewCell

@property (nonatomic) UILabel *titlelabel;

+ (instancetype)cellWithTableView:(UITableView *)tableView;

@end

@compatibility_alias DSPTableLeftCell DSPTableLeftViewCell;
