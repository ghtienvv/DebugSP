#import "UIBarButtonItem+DSP.h"

#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation UIBarButtonItem (DSP)

+ (UIBarButtonItem *)dsp_dspibleSpace {
    return [self dsp_systemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

+ (UIBarButtonItem *)dsp_fixedSpace {
    UIBarButtonItem *fixed = [self dsp_systemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixed.width = 60;
    return fixed;
}

+ (instancetype)dsp_systemItem:(UIBarButtonSystemItem)item target:(id)target action:(SEL)action {
    return [[self alloc] initWithBarButtonSystemItem:item target:target action:action];
}

+ (instancetype)dsp_itemWithCustomView:(UIView *)customView {
    return [[self alloc] initWithCustomView:customView];
}

+ (instancetype)dsp_backItemWithTitle:(NSString *)title {
    return [self dsp_itemWithTitle:title target:nil action:nil];
}

+ (instancetype)dsp_itemWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [[self alloc] initWithTitle:title style:UIBarButtonItemStylePlain target:target action:action];
}

+ (instancetype)dsp_doneStyleitemWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    return [[self alloc] initWithTitle:title style:UIBarButtonItemStyleDone target:target action:action];
}

+ (instancetype)dsp_itemWithImage:(UIImage *)image target:(id)target action:(SEL)action {
    return [[self alloc] initWithImage:image style:UIBarButtonItemStylePlain target:target action:action];
}

+ (instancetype)dsp_disabledSystemItem:(UIBarButtonSystemItem)system {
    UIBarButtonItem *item = [self dsp_systemItem:system target:nil action:nil];
    item.enabled = NO;
    return item;
}

+ (instancetype)dsp_disabledItemWithTitle:(NSString *)title style:(UIBarButtonItemStyle)style {
    UIBarButtonItem *item = [self dsp_itemWithTitle:title target:nil action:nil];
    item.enabled = NO;
    return item;
}

+ (instancetype)dsp_disabledItemWithImage:(UIImage *)image {
    UIBarButtonItem *item = [self dsp_itemWithImage:image target:nil action:nil];
    item.enabled = NO;
    return item;
}

- (UIBarButtonItem *)dsp_withTintColor:(UIColor *)tint {
    self.tintColor = tint;
    return self;
}

@end
