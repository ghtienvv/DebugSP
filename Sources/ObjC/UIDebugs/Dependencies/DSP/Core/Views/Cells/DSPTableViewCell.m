#import "DSPTableViewCell.h"
#import "DSPUtility.h"
#import "DSPColor.h"
#import "DSPTableView.h"

@interface UITableView (Internal)
// Exists at least since iOS 5
- (BOOL)_canPerformAction:(SEL)action forCell:(UITableViewCell *)cell sender:(id)sender;
- (void)_performAction:(SEL)action forCell:(UITableViewCell *)cell sender:(id)sender;
@end

@interface UITableViewCell (Internal)
// Exists at least since iOS 5
@property (nonatomic, readonly) DSPTableView *_tableView;
@end

@implementation DSPTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self postInit];
    }

    return self;
}

- (void)postInit {
    UIFont *cellFont = UIFont.dsp_defaultTableCellFont;
    self.titleLabel.font = cellFont;
    self.subtitleLabel.font = cellFont;
    self.subtitleLabel.textColor = DSPColor.deemphasizedTextColor;
    
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.subtitleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
    self.titleLabel.numberOfLines = 1;
    self.subtitleLabel.numberOfLines = 1;
}

- (UILabel *)titleLabel {
    return self.textLabel;
}

- (UILabel *)subtitleLabel {
    return self.detailTextLabel;
}

@end
