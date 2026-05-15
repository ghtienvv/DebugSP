#import "DSPColor.h"
#import "DSPExplorerToolbarItem.h"
#import "DSPUtility.h"

@interface DSPExplorerToolbarItem ()

@property (nonatomic) DSPExplorerToolbarItem *sibling;
@property (nonatomic, copy) NSString *title;
@property (nonatomic) UIImage *image;

@property (nonatomic, readonly, class) UIColor *defaultBackgroundColor;
@property (nonatomic, readonly, class) UIColor *highlightedBackgroundColor;
@property (nonatomic, readonly, class) UIColor *selectedBackgroundColor;

@end

@implementation DSPExplorerToolbarItem

#pragma mark - Public

+ (instancetype)itemWithTitle:(NSString *)title image:(UIImage *)image {
    return [self itemWithTitle:title image:image sibling:nil];
}

+ (instancetype)itemWithTitle:(NSString *)title image:(UIImage *)image sibling:(DSPExplorerToolbarItem *)backupItem {
    NSParameterAssert(title); NSParameterAssert(image);

    DSPExplorerToolbarItem *toolbarItem = [self buttonWithType:UIButtonTypeCustom];
    toolbarItem.sibling = backupItem;
    toolbarItem.title = title;
    toolbarItem.image = image;
    toolbarItem.tintColor = DSPColor.iconColor;
    toolbarItem.backgroundColor = self.defaultBackgroundColor;
    toolbarItem.titleLabel.font = [UIFont systemFontOfSize:12.0];
    [toolbarItem setTitle:title forState:UIControlStateNormal];
    [toolbarItem setImage:image forState:UIControlStateNormal];
    [toolbarItem setTitleColor:DSPColor.primaryTextColor forState:UIControlStateNormal];
    [toolbarItem setTitleColor:DSPColor.deemphasizedTextColor forState:UIControlStateDisabled];
    return toolbarItem;
}

- (DSPExplorerToolbarItem *)currentItem {
    if (!self.enabled && self.sibling) {
        return self.sibling.currentItem;
    }
    
    return self;
}


#pragma mark - Display Defaults

+ (NSDictionary<NSString *, id> *)titleAttributes {
    return @{ NSFontAttributeName : [UIFont systemFontOfSize:12.0] };
}

+ (UIColor *)highlightedBackgroundColor {
    return DSPColor.toolbarItemHighlightedColor;
}

+ (UIColor *)selectedBackgroundColor {
    return DSPColor.toolbarItemSelectedColor;
}

+ (UIColor *)defaultBackgroundColor {
    return UIColor.clearColor;
}

+ (CGFloat)topMargin {
    return 2.0;
}


#pragma mark - State Changes

- (void)setHighlighted:(BOOL)highlighted {
    super.highlighted = highlighted;
    [self updateColors];
}

- (void)setSelected:(BOOL)selected {
    super.selected = selected;
    [self updateColors];
}

- (void)setEnabled:(BOOL)enabled {
    if (self.enabled != enabled) {
        if (self.sibling) {
            if (enabled) { // Replace sibling with myself
                UIView *superview = self.sibling.superview;
                [self.sibling removeFromSuperview];
                self.frame = self.sibling.frame;
                [superview addSubview:self];
            } else { // Replace myself with sibling
                UIView *superview = self.superview;
                [self removeFromSuperview];
                self.sibling.frame = self.frame;
                [superview addSubview:self.sibling];
            }
        }
        
        super.enabled = enabled;
    }
}

+ (id)_selectedIndicatorImage { return nil; }

- (void)updateColors {
    // Background color
    if (self.highlighted) {
        self.backgroundColor = self.class.highlightedBackgroundColor;
    } else if (self.selected) {
        self.backgroundColor = self.class.selectedBackgroundColor;
    } else {
        self.backgroundColor = self.class.defaultBackgroundColor;
    }
}


#pragma mark - UIButton Layout Overrides

- (CGRect)titleRectForContentRect:(CGRect)contentRect {
    NSDictionary *attrs = [[self class] titleAttributes];
    // Bottom aligned and centered.
    CGRect titleRect = CGRectZero;
    CGSize titleSize = [self.title boundingRectWithSize:contentRect.size
                                                options:0
                                             attributes:attrs
                                                context:nil].size;
    titleSize = CGSizeMake(ceil(titleSize.width), ceil(titleSize.height));
    titleRect.size = titleSize;
    titleRect.origin.y = contentRect.origin.y + CGRectGetMaxY(contentRect) - titleSize.height;
    titleRect.origin.x = contentRect.origin.x + DSPFloor((contentRect.size.width - titleSize.width) / 2.0);
    return titleRect;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect {
    CGSize imageSize = self.image.size;
    CGRect titleRect = [self titleRectForContentRect:contentRect];
    CGFloat availableHeight = contentRect.size.height - titleRect.size.height - [[self class] topMargin];
    CGFloat originY = [[self class] topMargin] + DSPFloor((availableHeight - imageSize.height) / 2.0);
    CGFloat originX = DSPFloor((contentRect.size.width - imageSize.width) / 2.0);
    CGRect imageRect = CGRectMake(originX, originY, imageSize.width, imageSize.height);
    return imageRect;
}

@end
