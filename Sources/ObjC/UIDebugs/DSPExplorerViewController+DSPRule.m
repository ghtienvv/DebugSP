#import "DSPExplorerViewController+DSPRule.h"

#import "DSPExplorerToolbar+FWDebug.h"
#import "DSPExplorerToolbar.h"
#import "DSPExplorerToolbarItem.h"
#import "DSPUtility.h"
#import <objc/runtime.h>

static NSUInteger const DSPDSPExplorerModeDefault = 0;
static NSUInteger const DSPDSPExplorerModeSelect = 1;
static NSUInteger const DSPDSPExplorerModeMove = 2;

@interface DSPRuleOverlayView : UIView

@property (nonatomic) UIEdgeInsets distanceInsets;
@property (nonatomic) CGRect previousRect;
@property (nonatomic) CGRect selectedRect;
@property (nonatomic) UIView *highlightView;

- (void)updateWithSuperview:(UIView *)superView previousView:(UIView *)previousView selectedView:(UIView *)selectedView;

@end

@implementation DSPRuleOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = NO;

        _highlightView = [UIView new];
        _highlightView.layer.borderWidth = 1.0;
        [self addSubview:_highlightView];
    }
    return self;
}

- (void)updateWithSuperview:(UIView *)superView previousView:(UIView *)previousView selectedView:(UIView *)selectedView {
    self.previousRect = [superView convertRect:previousView.bounds fromView:previousView];
    self.selectedRect = [superView convertRect:selectedView.bounds fromView:selectedView];

    if (CGRectEqualToRect(self.previousRect, self.selectedRect)) {
        self.distanceInsets = UIEdgeInsetsZero;
    } else if (CGRectContainsRect(self.selectedRect, self.previousRect) || CGRectContainsRect(self.previousRect, self.selectedRect)) {
        self.distanceInsets = UIEdgeInsetsMake(
            fabs(CGRectGetMinY(self.selectedRect) - CGRectGetMinY(self.previousRect)),
            fabs(CGRectGetMinX(self.selectedRect) - CGRectGetMinX(self.previousRect)),
            fabs(CGRectGetMaxY(self.selectedRect) - CGRectGetMaxY(self.previousRect)),
            fabs(CGRectGetMaxX(self.selectedRect) - CGRectGetMaxX(self.previousRect))
        );
    } else {
        self.distanceInsets = UIEdgeInsetsMake(
            MAX(0, CGRectGetMinY(self.previousRect) - CGRectGetMaxY(self.selectedRect)),
            MAX(0, CGRectGetMinX(self.previousRect) - CGRectGetMaxX(self.selectedRect)),
            MAX(0, CGRectGetMinY(self.selectedRect) - CGRectGetMaxY(self.previousRect)),
            MAX(0, CGRectGetMinX(self.selectedRect) - CGRectGetMaxX(self.previousRect))
        );
    }

    UIColor *overlayColor = [DSPUtility consistentRandomColorForObject:previousView];
    self.highlightView.backgroundColor = [overlayColor colorWithAlphaComponent:0.2];
    self.highlightView.layer.borderColor = overlayColor.CGColor;
    self.highlightView.frame = self.previousRect;

    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    if (CGRectEqualToRect(self.previousRect, self.selectedRect)) {
        return;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return;
    }

    if (CGRectContainsRect(self.selectedRect, self.previousRect) || CGRectContainsRect(self.previousRect, self.selectedRect)) {
        CGRect superRect = CGRectContainsRect(self.selectedRect, self.previousRect) ? self.selectedRect : self.previousRect;
        CGRect subRect = CGRectContainsRect(self.selectedRect, self.previousRect) ? self.previousRect : self.selectedRect;

        [self drawOverlayInContext:context edge:UIRectEdgeTop insets:self.distanceInsets start:CGPointMake(CGRectGetMidX(subRect), CGRectGetMinY(subRect)) end:CGPointMake(CGRectGetMidX(subRect), CGRectGetMinY(superRect))];
        [self drawOverlayInContext:context edge:UIRectEdgeBottom insets:self.distanceInsets start:CGPointMake(CGRectGetMidX(subRect), CGRectGetMaxY(subRect)) end:CGPointMake(CGRectGetMidX(subRect), CGRectGetMaxY(superRect))];
        [self drawOverlayInContext:context edge:UIRectEdgeLeft insets:self.distanceInsets start:CGPointMake(CGRectGetMinX(subRect), CGRectGetMidY(subRect)) end:CGPointMake(CGRectGetMinX(superRect), CGRectGetMidY(subRect))];
        [self drawOverlayInContext:context edge:UIRectEdgeRight insets:self.distanceInsets start:CGPointMake(CGRectGetMaxX(subRect), CGRectGetMidY(subRect)) end:CGPointMake(CGRectGetMaxX(superRect), CGRectGetMidY(subRect))];
    } else {
        if (self.distanceInsets.top > 0) {
            [self drawOverlayInContext:context edge:UIRectEdgeTop insets:self.distanceInsets start:CGPointMake(CGRectGetMidX(self.previousRect), CGRectGetMinY(self.previousRect)) end:CGPointMake(CGRectGetMidX(self.previousRect), CGRectGetMaxY(self.selectedRect))];
        }
        if (self.distanceInsets.bottom > 0) {
            [self drawOverlayInContext:context edge:UIRectEdgeBottom insets:self.distanceInsets start:CGPointMake(CGRectGetMidX(self.previousRect), CGRectGetMaxY(self.previousRect)) end:CGPointMake(CGRectGetMidX(self.previousRect), CGRectGetMinY(self.selectedRect))];
        }
        if (self.distanceInsets.left > 0) {
            [self drawOverlayInContext:context edge:UIRectEdgeLeft insets:self.distanceInsets start:CGPointMake(CGRectGetMinX(self.previousRect), CGRectGetMidY(self.previousRect)) end:CGPointMake(CGRectGetMaxX(self.selectedRect), CGRectGetMidY(self.previousRect))];
        }
        if (self.distanceInsets.right > 0) {
            [self drawOverlayInContext:context edge:UIRectEdgeRight insets:self.distanceInsets start:CGPointMake(CGRectGetMaxX(self.previousRect), CGRectGetMidY(self.previousRect)) end:CGPointMake(CGRectGetMinX(self.selectedRect), CGRectGetMidY(self.previousRect))];
        }
    }
}

- (void)drawOverlayInContext:(CGContextRef)context edge:(UIRectEdge)edge insets:(UIEdgeInsets)insets start:(CGPoint)start end:(CGPoint)end {
    CGFloat lineWidth = 1.0;
    CGFloat rulerWidth = 8.0;
    NSDictionary<NSAttributedStringKey, id> *attributes = @{
        NSFontAttributeName: [UIFont systemFontOfSize:12.0],
        NSForegroundColorAttributeName: UIColor.redColor,
    };
    CGFloat lineHeight = [UIFont systemFontOfSize:12.0].lineHeight;
    CGFloat spacing = 4.0;

    CGContextSetLineWidth(context, lineWidth);
    CGContextSetStrokeColorWithColor(context, UIColor.redColor.CGColor);

    NSString *label = @"0";
    switch (edge) {
        case UIRectEdgeTop:
            label = [NSString stringWithFormat:@"%g", insets.top];
            CGContextMoveToPoint(context, start.x - rulerWidth / 2.0, start.y - lineWidth / 2.0);
            CGContextAddLineToPoint(context, start.x + rulerWidth / 2.0, start.y - lineWidth / 2.0);
            CGContextMoveToPoint(context, start.x, start.y);
            CGContextAddLineToPoint(context, end.x, end.y);
            CGContextMoveToPoint(context, end.x - rulerWidth / 2.0, end.y + lineWidth / 2.0);
            CGContextAddLineToPoint(context, end.x + rulerWidth / 2.0, end.y + lineWidth / 2.0);
            CGContextStrokePath(context);
            [label drawAtPoint:CGPointMake(start.x + spacing, end.y + insets.top / 2.0 - lineHeight / 2.0) withAttributes:attributes];
            break;
        case UIRectEdgeBottom:
            label = [NSString stringWithFormat:@"%g", insets.bottom];
            CGContextMoveToPoint(context, start.x - rulerWidth / 2.0, start.y + lineWidth / 2.0);
            CGContextAddLineToPoint(context, start.x + rulerWidth / 2.0, start.y + lineWidth / 2.0);
            CGContextMoveToPoint(context, start.x, start.y);
            CGContextAddLineToPoint(context, end.x, end.y);
            CGContextMoveToPoint(context, end.x - rulerWidth / 2.0, end.y - lineWidth / 2.0);
            CGContextAddLineToPoint(context, end.x + rulerWidth / 2.0, end.y - lineWidth / 2.0);
            CGContextStrokePath(context);
            [label drawAtPoint:CGPointMake(start.x + spacing, start.y + insets.bottom / 2.0 - lineHeight / 2.0) withAttributes:attributes];
            break;
        case UIRectEdgeLeft: {
            label = [NSString stringWithFormat:@"%g", insets.left];
            CGContextMoveToPoint(context, start.x - lineWidth / 2.0, start.y - rulerWidth / 2.0);
            CGContextAddLineToPoint(context, start.x - lineWidth / 2.0, start.y + rulerWidth / 2.0);
            CGContextMoveToPoint(context, start.x, start.y);
            CGContextAddLineToPoint(context, end.x, end.y);
            CGContextMoveToPoint(context, end.x + lineWidth / 2.0, end.y - rulerWidth / 2.0);
            CGContextAddLineToPoint(context, end.x + lineWidth / 2.0, end.y + rulerWidth / 2.0);
            CGContextStrokePath(context);
            CGSize size = [label boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attributes context:nil].size;
            [label drawAtPoint:CGPointMake(end.x + insets.left / 2.0 - size.width / 2.0, start.y - spacing - size.height) withAttributes:attributes];
            break;
        }
        case UIRectEdgeRight: {
            label = [NSString stringWithFormat:@"%g", insets.right];
            CGContextMoveToPoint(context, start.x + lineWidth / 2.0, start.y - rulerWidth / 2.0);
            CGContextAddLineToPoint(context, start.x + lineWidth / 2.0, start.y + rulerWidth / 2.0);
            CGContextMoveToPoint(context, start.x, start.y);
            CGContextAddLineToPoint(context, end.x, end.y);
            CGContextMoveToPoint(context, end.x - lineWidth / 2.0, end.y - rulerWidth / 2.0);
            CGContextAddLineToPoint(context, end.x - lineWidth / 2.0, end.y + rulerWidth / 2.0);
            CGContextStrokePath(context);
            CGSize size = [label boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attributes context:nil].size;
            [label drawAtPoint:CGPointMake(start.x + insets.right / 2.0 - size.width / 2.0, start.y - spacing - size.height) withAttributes:attributes];
            break;
        }
        default:
            break;
    }
}

@end

@implementation DSPExplorerViewController (DSPRule)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originalSetCurrentMode = class_getInstanceMethod(self, NSSelectorFromString(@"setCurrentMode:"));
        Method swizzledSetCurrentMode = class_getInstanceMethod(self, @selector(dsp_setCurrentMode:));
        method_exchangeImplementations(originalSetCurrentMode, swizzledSetCurrentMode);

        Method originalSetSelectedView = class_getInstanceMethod(self, NSSelectorFromString(@"setSelectedView:"));
        Method swizzledSetSelectedView = class_getInstanceMethod(self, @selector(dsp_setSelectedView:));
        method_exchangeImplementations(originalSetSelectedView, swizzledSetSelectedView);

        Method originalUpdateButtonStates = class_getInstanceMethod(self, NSSelectorFromString(@"updateButtonStates"));
        Method swizzledUpdateButtonStates = class_getInstanceMethod(self, @selector(dsp_updateButtonStates));
        method_exchangeImplementations(originalUpdateButtonStates, swizzledUpdateButtonStates);
    });
}

- (void)dsp_syncToolbarSelectionState {
    NSUInteger currentMode = [[self valueForKey:@"currentMode"] unsignedIntegerValue];
    BOOL isSelecting = currentMode == DSPDSPExplorerModeSelect;

    self.explorerToolbar.selectItem.selected = isSelecting && !self.dsp_ruleEnabled;
    self.explorerToolbar.fwDebugFpsItem.selected = isSelecting && self.dsp_ruleEnabled;
}

- (BOOL)dsp_ruleEnabled {
    return [objc_getAssociatedObject(self, @selector(dsp_ruleEnabled)) boolValue];
}

- (void)setDsp_ruleEnabled:(BOOL)enabled {
    objc_setAssociatedObject(self, @selector(dsp_ruleEnabled), @(enabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self dsp_syncToolbarSelectionState];
    if (!enabled) {
        [self dsp_removeRuleOverlay];
    }
}

- (void)dsp_activateSelectMode {
    NSUInteger currentMode = [[self valueForKey:@"currentMode"] unsignedIntegerValue];
    if (currentMode != DSPDSPExplorerModeSelect) {
        [self toggleSelectTool];
    }
}

- (void)dsp_resetToDefaultMode {
    NSUInteger currentMode = [[self valueForKey:@"currentMode"] unsignedIntegerValue];
    if (currentMode == DSPDSPExplorerModeSelect) {
        [self toggleSelectTool];
    } else if (currentMode == DSPDSPExplorerModeMove) {
        [self toggleMoveTool];
    }
    self.dsp_ruleEnabled = NO;
    [self dsp_removeRuleOverlay];
}

- (void)dsp_removeRuleOverlay {
    DSPRuleOverlayView *overlay = objc_getAssociatedObject(self, @selector(dsp_removeRuleOverlay));
    [overlay removeFromSuperview];
}

- (void)dsp_setCurrentMode:(NSUInteger)currentMode {
    [self dsp_setCurrentMode:currentMode];
    self.explorerToolbar.fwDebugFpsItem.fwDebugShowRuler = YES;
    if (currentMode != DSPDSPExplorerModeSelect) {
        self.dsp_ruleEnabled = NO;
    }
    [self dsp_syncToolbarSelectionState];
}

- (void)dsp_updateButtonStates {
    [self dsp_updateButtonStates];
    [self dsp_syncToolbarSelectionState];
}

- (void)dsp_setSelectedView:(UIView *)selectedView {
    UIView *previousView = self.dsp_ruleEnabled ? [self valueForKey:@"selectedView"] : nil;
    [self dsp_setSelectedView:selectedView];
    [self dsp_syncToolbarSelectionState];

    if (!self.dsp_ruleEnabled) {
        return;
    }

    if (!previousView || !selectedView || previousView == selectedView) {
        [self dsp_removeRuleOverlay];
        return;
    }

    DSPRuleOverlayView *overlay = objc_getAssociatedObject(self, @selector(dsp_removeRuleOverlay));
    if (!overlay) {
        overlay = [[DSPRuleOverlayView alloc] initWithFrame:self.view.bounds];
        objc_setAssociatedObject(self, @selector(dsp_removeRuleOverlay), overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    overlay.frame = self.view.bounds;
    [overlay updateWithSuperview:self.view previousView:previousView selectedView:selectedView];
    [self.view addSubview:overlay];
    [self.view bringSubviewToFront:overlay];
    [self.view bringSubviewToFront:self.explorerToolbar];

    UIEdgeInsets distanceInsets = overlay.distanceInsets;
    self.explorerToolbar.selectedViewDescription = [NSString stringWithFormat:@"Distance: {%g, %g, %g, %g}", distanceInsets.top, distanceInsets.left, distanceInsets.bottom, distanceInsets.right];
    self.explorerToolbar.selectedViewOverlayColor = [DSPUtility consistentRandomColorForObject:previousView];
}

@end
