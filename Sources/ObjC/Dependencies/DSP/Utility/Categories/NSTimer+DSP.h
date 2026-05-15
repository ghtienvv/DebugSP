#import <Foundation/Foundation.h>

typedef void (^VoidBlock)(void);

@interface NSTimer (Blocks)

+ (instancetype)dsp_fireSecondsFromNow:(NSTimeInterval)delay block:(VoidBlock)block;

// Forward declaration
//+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer *timer))block;

@end
