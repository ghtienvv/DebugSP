#import <UIKit/UIKit.h>

typedef void (^GestureBlock)(UIGestureRecognizer *gesture);


@interface UIGestureRecognizer (Blocks)

+ (instancetype)dsp_action:(GestureBlock)action;

@property (nonatomic, setter=dsp_setAction:) GestureBlock dsp_action;

@end

