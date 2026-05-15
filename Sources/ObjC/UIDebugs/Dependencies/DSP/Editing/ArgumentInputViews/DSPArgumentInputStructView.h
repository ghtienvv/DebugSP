#import "DSPArgumentInputView.h"

@interface DSPArgumentInputStructView : DSPArgumentInputView

/// Enable displaying ivar names for custom struct types
+ (void)registerFieldNames:(NSArray<NSString *> *)names forTypeEncoding:(NSString *)typeEncoding;

@end
