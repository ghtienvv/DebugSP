#import <UIKit/UIKit.h>

@interface DSPTableViewCell : UITableViewCell

/// Use this instead of .textLabel
@property (nonatomic, readonly) UILabel *titleLabel;
/// Use this instead of .detailTextLabel
@property (nonatomic, readonly) UILabel *subtitleLabel;

/// Subclasses can override this instead of initializers to
/// perform additional initialization without lots of boilerplate.
/// Remember to call super!
- (void)postInit;

@end
