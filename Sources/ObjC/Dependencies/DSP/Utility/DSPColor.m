#import "DSPColor.h"
#import "DSPUtility.h"

#define DSPDynamicColor(dynamic, static) ({ \
    UIColor *c; \
    if (@available(iOS 13.0, *)) { \
        c = [UIColor dynamic]; \
    } else { \
        c = [UIColor static]; \
    } \
    c; \
});

@implementation DSPColor

#pragma mark - Background Colors

+ (UIColor *)primaryBackgroundColor {
    return DSPDynamicColor(systemBackgroundColor, whiteColor);
}

+ (UIColor *)primaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self primaryBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)secondaryBackgroundColor {
    return DSPDynamicColor(
        secondarySystemBackgroundColor,
        colorWithHue:2.0/3.0 saturation:0.02 brightness:0.97 alpha:1
    );
}

+ (UIColor *)secondaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self secondaryBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)tertiaryBackgroundColor {
    // All the background/fill colors are varying shades
    // of white and black with really low alpha levels.
    // We use systemGray4Color instead to avoid alpha issues.
    return DSPDynamicColor(systemGray4Color, lightGrayColor);
}

+ (UIColor *)tertiaryBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self tertiaryBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)groupedBackgroundColor {
    return DSPDynamicColor(
        systemGroupedBackgroundColor,
        colorWithHue:2.0/3.0 saturation:0.02 brightness:0.97 alpha:1
    );
}

+ (UIColor *)groupedBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self groupedBackgroundColor] colorWithAlphaComponent:alpha];
}

+ (UIColor *)secondaryGroupedBackgroundColor {
    return DSPDynamicColor(secondarySystemGroupedBackgroundColor, whiteColor);
}

+ (UIColor *)secondaryGroupedBackgroundColorWithAlpha:(CGFloat)alpha {
    return [[self secondaryGroupedBackgroundColor] colorWithAlphaComponent:alpha];
}

#pragma mark - Text colors

+ (UIColor *)primaryTextColor {
    return DSPDynamicColor(labelColor, blackColor);
}

+ (UIColor *)deemphasizedTextColor {
    return DSPDynamicColor(secondaryLabelColor, lightGrayColor);
}

#pragma mark - UI Element Colors

+ (UIColor *)tintColor {
    #if DSP_AT_LEAST_IOS13_SDK
    if (@available(iOS 13.0, *)) {
        return UIColor.systemBlueColor;
    } else {
        return UIApplication.sharedApplication.keyWindow.tintColor;
    }
    #else
    return UIApplication.sharedApplication.keyWindow.tintColor;
    #endif
}

+ (UIColor *)scrollViewBackgroundColor {
    return DSPDynamicColor(
        systemGroupedBackgroundColor,
        colorWithHue:2.0/3.0 saturation:0.02 brightness:0.95 alpha:1
    );
}

+ (UIColor *)iconColor {
    return DSPDynamicColor(labelColor, blackColor);
}

+ (UIColor *)borderColor {
    return [self primaryBackgroundColor];
}

+ (UIColor *)toolbarItemHighlightedColor {
    return DSPDynamicColor(
        quaternaryLabelColor,
        colorWithHue:2.0/3.0 saturation:0.1 brightness:0.25 alpha:0.6
    );
}

+ (UIColor *)toolbarItemSelectedColor {
    return DSPDynamicColor(
        secondaryLabelColor,
        colorWithHue:2.0/3.0 saturation:0.1 brightness:0.25 alpha:0.68
    );
}

+ (UIColor *)hairlineColor {
    return DSPDynamicColor(systemGray3Color, colorWithWhite:0.75 alpha:1);
}

+ (UIColor *)destructiveColor {
    return DSPDynamicColor(systemRedColor, redColor);
}

@end
