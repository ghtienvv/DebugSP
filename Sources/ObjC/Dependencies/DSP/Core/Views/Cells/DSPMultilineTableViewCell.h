#import "DSPTableViewCell.h"

/// A cell with both labels set to be multi-line capable.
@interface DSPMultilineTableViewCell : DSPTableViewCell

+ (CGFloat)preferredHeightWithAttributedText:(NSAttributedString *)attributedText
                                    maxWidth:(CGFloat)contentViewWidth
                                       style:(UITableViewStyle)style
                              showsAccessory:(BOOL)showsAccessory;

@end

/// A \c DSPMultilineTableViewCell initialized with \c UITableViewCellStyleSubtitle
@interface DSPMultilineDetailTableViewCell : DSPMultilineTableViewCell

@end
