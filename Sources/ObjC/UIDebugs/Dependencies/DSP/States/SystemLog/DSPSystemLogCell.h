#import "DSPTableViewCell.h"

@class DSPSystemLogMessage;

extern NSString *const kDSPSystemLogCellIdentifier;

@interface DSPSystemLogCell : DSPTableViewCell

@property (nonatomic) DSPSystemLogMessage *logMessage;
@property (nonatomic, copy) NSString *highlightedText;

+ (NSString *)displayedTextForLogMessage:(DSPSystemLogMessage *)logMessage;
+ (CGFloat)preferredHeightForLogMessage:(DSPSystemLogMessage *)logMessage inWidth:(CGFloat)width;

@end
