#import "NSDateFormatter+DSP.h"

@implementation NSDateFormatter (DSP)

+ (NSString *)dsp_stringFrom:(NSDate *)date format:(DSPDateFormat)format {
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [NSDateFormatter new];
    }
    
    switch (format) {
        case DSPDateFormatClock:
            formatter.dateFormat = @"h:mm a";
            break;
        case DSPDateFormatPreciseClock:
            formatter.dateFormat = @"h:mm:ss a";
            break;
        case DSPDateFormatVerbose:
            formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
            break;
    }
    
    return [formatter stringFromDate:date];
}

@end
