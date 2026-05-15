#import "CALayer+DSP.h"

@interface CALayer (Private)
@property (nonatomic) BOOL continuousCorners;
@end

@implementation CALayer (DSP)

static BOOL respondsToContinuousCorners = NO;

+ (void)load {
    respondsToContinuousCorners = [CALayer
        instancesRespondToSelector:@selector(setContinuousCorners:)
    ];
}

- (BOOL)dsp_continuousCorners {
    if (respondsToContinuousCorners) {
        return self.continuousCorners;
    }
    
    return NO;
}

- (void)setDsp_continuousCorners:(BOOL)enabled {
    if (respondsToContinuousCorners) {
        if (@available(iOS 13, *)) {
            self.cornerCurve = kCACornerCurveContinuous;
        } else {
            self.continuousCorners = enabled;
        }
    }
}

@end
