#import "UIFont+DSP.h"

#define kDSPDefaultCellFontSize 12.0

@implementation UIFont (DSP)

+ (UIFont *)dsp_defaultTableCellFont {
    static UIFont *defaultTableCellFont = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultTableCellFont = [UIFont systemFontOfSize:kDSPDefaultCellFontSize];
    });

    return defaultTableCellFont;
}

+ (UIFont *)dsp_codeFont {
    // Actually only available in iOS 13, the SDK headers are wrong
    if (@available(iOS 13, *)) {
        return [self monospacedSystemFontOfSize:kDSPDefaultCellFontSize weight:UIFontWeightRegular];
    } else {
        return [self fontWithName:@"Menlo-Regular" size:kDSPDefaultCellFontSize];
    }
}

+ (UIFont *)dsp_smallCodeFont {
        // Actually only available in iOS 13, the SDK headers are wrong
    if (@available(iOS 13, *)) {
        return [self monospacedSystemFontOfSize:self.smallSystemFontSize weight:UIFontWeightRegular];
    } else {
        return [self fontWithName:@"Menlo-Regular" size:self.smallSystemFontSize];
    }
}

@end
