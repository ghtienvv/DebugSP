#import <UIKit/UIKit.h>

#define Padding(p) UIEdgeInsetsMake(p, p, p, p)

@interface UIView (DSP_Layout)

- (void)dsp_centerInView:(UIView *)view;
- (void)dsp_pinEdgesTo:(UIView *)view;
- (void)dsp_pinEdgesTo:(UIView *)view withInsets:(UIEdgeInsets)insets;
- (void)dsp_pinEdgesToSuperview;
- (void)dsp_pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets;
- (void)dsp_pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets aboveView:(UIView *)sibling;
- (void)dsp_pinEdgesToSuperviewWithInsets:(UIEdgeInsets)insets belowView:(UIView *)sibling;

@end
