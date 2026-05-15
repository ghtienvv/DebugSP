#import <UIKit/UIKit.h>

@interface UIMenu (DSP)

+ (instancetype)dsp_inlineMenuWithTitle:(NSString *)title
                                   image:(UIImage *)image
                                children:(NSArray<UIMenuElement *> *)children;

- (instancetype)dsp_collapsed;

@end
