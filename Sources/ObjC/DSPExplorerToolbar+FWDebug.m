#import "DSPExplorerToolbar+FWDebug.h"

#import "DSPColor.h"
#import "DSPResources.h"
#import <objc/runtime.h>

@interface DSPExplorerToolbarItem ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic) UIImage *image;

@end

@implementation DSPExplorerToolbarItem (FWDebug)

- (BOOL)fwDebugShowRuler {
    return [objc_getAssociatedObject(self, @selector(fwDebugShowRuler)) boolValue];
}

- (void)setFwDebugShowRuler:(BOOL)showRuler {
    objc_setAssociatedObject(self, @selector(fwDebugShowRuler), @(showRuler), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.title = @"Rule";
    self.image = [self dsp_rulerImage];
    self.titleLabel.font = [UIFont systemFontOfSize:12.0];
    [self setTitleColor:DSPColor.primaryTextColor forState:UIControlStateNormal];
    [self setTitle:self.title forState:UIControlStateNormal];
    [self setImage:self.image forState:UIControlStateNormal];
}

- (BOOL)fwDebugIsRuler {
    return [objc_getAssociatedObject(self, @selector(fwDebugIsRuler)) boolValue];
}

- (void)setFwDebugIsRuler:(BOOL)isRuler {
    objc_setAssociatedObject(self, @selector(fwDebugIsRuler), @(isRuler), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (self.fwDebugShowRuler) {
        self.title = @"Rule";
        self.image = [self dsp_rulerImage];
    } else {
        self.title = isRuler ? @"ruler" : @"select";
        self.image = isRuler ? [self dsp_rulerImage] : DSPResources.selectIcon;
    }
    self.titleLabel.font = [UIFont systemFontOfSize:12.0];
    [self setTitleColor:DSPColor.primaryTextColor forState:UIControlStateNormal];
    [self setTitle:self.title forState:UIControlStateNormal];
    [self setImage:self.image forState:UIControlStateNormal];
}

- (UIImage *)dsp_rulerImage {
    CGSize size = CGSizeMake(21.0, 21.0);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return nil;
    }

    CGFloat lineWidth = 1.5;
    CGFloat rulerWidth = 6.0;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(lineWidth / 2.0, size.height / 2.0)];
    [path addLineToPoint:CGPointMake(size.width - lineWidth, size.height / 2.0)];
    [path moveToPoint:CGPointMake(lineWidth / 2.0, size.height / 2.0 - rulerWidth / 2.0)];
    [path addLineToPoint:CGPointMake(lineWidth / 2.0, size.height / 2.0 + rulerWidth / 2.0)];
    [path moveToPoint:CGPointMake(size.width - lineWidth, size.height / 2.0 - rulerWidth / 2.0)];
    [path addLineToPoint:CGPointMake(size.width - lineWidth, size.height / 2.0 + rulerWidth / 2.0)];

    CGContextSetLineWidth(context, lineWidth);
    [DSPColor.primaryTextColor setStroke];
    CGContextAddPath(context, path.CGPath);
    CGContextDrawPath(context, kCGPathStroke);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end

@implementation DSPExplorerToolbar (FWDebug)

- (DSPExplorerToolbarItem *)fwDebugFpsItem {
    DSPExplorerToolbarItem *item = objc_getAssociatedObject(self, _cmd);
    if (!item) {
        item = [DSPExplorerToolbarItem buttonWithType:UIButtonTypeCustom];
        item.title = @"";
        item.image = [UIImage new];
        item.tintColor = DSPColor.iconColor;
        item.backgroundColor = UIColor.clearColor;
        item.titleLabel.font = [UIFont systemFontOfSize:12.0];
        [item setTitle:item.title forState:UIControlStateNormal];
        [item setImage:item.image forState:UIControlStateNormal];
        [item setTitleColor:DSPColor.primaryTextColor forState:UIControlStateNormal];
        [item setTitleColor:DSPColor.deemphasizedTextColor forState:UIControlStateDisabled];
        [self addSubview:item];
        objc_setAssociatedObject(self, _cmd, item, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return item;
}

@end
