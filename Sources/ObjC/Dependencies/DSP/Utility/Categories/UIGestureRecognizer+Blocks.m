#import "UIGestureRecognizer+Blocks.h"
#import <objc/runtime.h>


@implementation UIGestureRecognizer (Blocks)

static void * actionKey;

+ (instancetype)dsp_action:(GestureBlock)action {
    UIGestureRecognizer *gesture = [[self alloc] initWithTarget:nil action:nil];
    [gesture addTarget:gesture action:@selector(dsp_invoke)];
    gesture.dsp_action = action;
    return gesture;
}

- (void)dsp_invoke {
    self.dsp_action(self);
}

- (GestureBlock)dsp_action {
    return objc_getAssociatedObject(self, &actionKey);
}

- (void)dsp_setAction:(GestureBlock)action {
    objc_setAssociatedObject(self, &actionKey, action, OBJC_ASSOCIATION_COPY);
}

@end
