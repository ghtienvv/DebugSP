#import <UIKit/UIKit.h>

#define DSPBarButtonItem(title, tgt, sel) \
    [UIBarButtonItem dsp_itemWithTitle:title target:tgt action:sel]
#define DSPBarButtonItemSystem(item, tgt, sel) \
    [UIBarButtonItem dsp_systemItem:UIBarButtonSystemItem##item target:tgt action:sel]

@interface UIBarButtonItem (DSP)

@property (nonatomic, readonly, class) UIBarButtonItem *dsp_dspibleSpace;
@property (nonatomic, readonly, class) UIBarButtonItem *dsp_fixedSpace;

+ (instancetype)dsp_itemWithCustomView:(UIView *)customView;
+ (instancetype)dsp_backItemWithTitle:(NSString *)title;

+ (instancetype)dsp_systemItem:(UIBarButtonSystemItem)item target:(id)target action:(SEL)action;

+ (instancetype)dsp_itemWithTitle:(NSString *)title target:(id)target action:(SEL)action;
+ (instancetype)dsp_doneStyleitemWithTitle:(NSString *)title target:(id)target action:(SEL)action;

+ (instancetype)dsp_itemWithImage:(UIImage *)image target:(id)target action:(SEL)action;

+ (instancetype)dsp_disabledSystemItem:(UIBarButtonSystemItem)item;
+ (instancetype)dsp_disabledItemWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style;
+ (instancetype)dsp_disabledItemWithImage:(UIImage *)image;

/// @return the receiver
- (UIBarButtonItem *)dsp_withTintColor:(UIColor *)tint;

- (void)_setWidth:(CGFloat)width;

@end
