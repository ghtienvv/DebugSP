#import "DSPSystemLogCell.h"
#import "DSPSystemLogMessage.h"
#import "UIFont+DSP.h"
#import "NSDateFormatter+DSP.h"

NSString *const kDSPSystemLogCellIdentifier = @"DSPSystemLogCellIdentifier";

@interface DSPSystemLogCell ()

@property (nonatomic) UILabel *logMessageLabel;
@property (nonatomic) NSAttributedString *logMessageAttributedText;

@end

@implementation DSPSystemLogCell

- (void)postInit {
    [super postInit];
    
    self.logMessageLabel = [UILabel new];
    self.logMessageLabel.numberOfLines = 0;
    self.separatorInset = UIEdgeInsetsZero;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    [self.contentView addSubview:self.logMessageLabel];
}

- (void)setLogMessage:(DSPSystemLogMessage *)logMessage {
    if (![_logMessage isEqual:logMessage]) {
        _logMessage = logMessage;
        self.logMessageAttributedText = nil;
        [self setNeedsLayout];
    }
}

- (void)setHighlightedText:(NSString *)highlightedText {
    if (![_highlightedText isEqual:highlightedText]) {
        _highlightedText = highlightedText;
        self.logMessageAttributedText = nil;
        [self setNeedsLayout];
    }
}

- (NSAttributedString *)logMessageAttributedText {
    if (!_logMessageAttributedText) {
        _logMessageAttributedText = [[self class] attributedTextForLogMessage:self.logMessage highlightedText:self.highlightedText];
    }
    return _logMessageAttributedText;
}

static const UIEdgeInsets kDSPLogMessageCellInsets = {10.0, 10.0, 10.0, 10.0};

- (void)layoutSubviews {
    [super layoutSubviews];

    self.logMessageLabel.attributedText = self.logMessageAttributedText;
    self.logMessageLabel.frame = UIEdgeInsetsInsetRect(self.contentView.bounds, kDSPLogMessageCellInsets);
}


#pragma mark - Stateless helpers

+ (NSAttributedString *)attributedTextForLogMessage:(DSPSystemLogMessage *)logMessage highlightedText:(NSString *)highlightedText {
    NSString *text = [self displayedTextForLogMessage:logMessage];
    NSDictionary<NSString *, id> *attributes = @{ NSFontAttributeName : UIFont.dsp_codeFont };
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];

    if (highlightedText.length > 0) {
        NSMutableAttributedString *mutableAttributedText = attributedText.mutableCopy;
        NSMutableDictionary<NSString *, id> *highlightAttributes = attributes.mutableCopy;
        highlightAttributes[NSBackgroundColorAttributeName] = UIColor.yellowColor;
        
        NSRange remainingSearchRange = NSMakeRange(0, text.length);
        while (remainingSearchRange.location < text.length) {
            remainingSearchRange.length = text.length - remainingSearchRange.location;
            NSRange foundRange = [text rangeOfString:highlightedText options:NSCaseInsensitiveSearch range:remainingSearchRange];
            if (foundRange.location != NSNotFound) {
                remainingSearchRange.location = foundRange.location + foundRange.length;
                [mutableAttributedText setAttributes:highlightAttributes range:foundRange];
            } else {
                break;
            }
        }
        attributedText = mutableAttributedText;
    }

    return attributedText;
}

+ (NSString *)displayedTextForLogMessage:(DSPSystemLogMessage *)logMessage {
    return [NSString stringWithFormat:@"%@: %@", [self logTimeStringFromDate:logMessage.date], logMessage.messageText];
}

+ (CGFloat)preferredHeightForLogMessage:(DSPSystemLogMessage *)logMessage inWidth:(CGFloat)width {
    UIEdgeInsets insets = kDSPLogMessageCellInsets;
    CGFloat availableWidth = width - insets.left - insets.right;
    NSAttributedString *attributedLogText = [self attributedTextForLogMessage:logMessage highlightedText:nil];
    CGSize labelSize = [attributedLogText boundingRectWithSize:CGSizeMake(availableWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading context:nil].size;
    return labelSize.height + insets.top + insets.bottom;
}

+ (NSString *)logTimeStringFromDate:(NSDate *)date {
    return [NSDateFormatter dsp_stringFrom:date format:DSPDateFormatVerbose];
}

@end
