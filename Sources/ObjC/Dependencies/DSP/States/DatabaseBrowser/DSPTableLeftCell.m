#import "DSPTableLeftCell.h"

static NSString * const kDSPTableLeftCellReuseIdentifier = @"DSPTableLeftCell";

@implementation DSPTableLeftCell

+ (instancetype)cellWithTableView:(UITableView *)tableView {
    DSPTableLeftCell *cell = [tableView dequeueReusableCellWithIdentifier:kDSPTableLeftCellReuseIdentifier];
    
    if (!cell) {
        cell = [[DSPTableLeftCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kDSPTableLeftCellReuseIdentifier];
        UILabel *textLabel               = [UILabel new];
        textLabel.textAlignment          = NSTextAlignmentCenter;
        textLabel.font                   = [UIFont systemFontOfSize:13.0];
        [cell.contentView addSubview:textLabel];
        cell.titlelabel = textLabel;
    }
    
    return cell;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.titlelabel.frame = self.contentView.frame;
}
@end
