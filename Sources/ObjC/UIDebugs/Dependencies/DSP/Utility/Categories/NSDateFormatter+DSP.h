#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, DSPDateFormat) {
    // hour:minute [AM|PM]
    DSPDateFormatClock,
    // hour:minute:second [AM|PM]
    DSPDateFormatPreciseClock,
    // year-month-day hour:minute:second.millisecond
    DSPDateFormatVerbose,
};

@interface NSDateFormatter (DSP)

+ (NSString *)dsp_stringFrom:(NSDate *)date format:(DSPDateFormat)format;

@end
