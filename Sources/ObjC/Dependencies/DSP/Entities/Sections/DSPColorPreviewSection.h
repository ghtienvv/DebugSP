#import "DSPSingleRowSection.h"
#import "DSPObjectInfoSection.h"

@interface DSPColorPreviewSection : DSPSingleRowSection <DSPObjectInfoSection>

+ (instancetype)forObject:(UIColor *)color;

@end
