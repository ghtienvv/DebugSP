#import "DSPTableColumnHeader.h"
#import "DSPColor.h"
#import "UIFont+DSP.h"
#import "DSPUtility.h"

static const CGFloat kMargin = 5;
static const CGFloat kArrowWidth = 20;

@interface DSPTableColumnHeader ()
@property (nonatomic, readonly) UILabel *arrowLabel;
@property (nonatomic, readonly) UIView *lineView;
@end

@implementation DSPTableColumnHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = DSPColor.secondaryBackgroundColor;
        
        _titleLabel = [UILabel new];
        _titleLabel.font = UIFont.dsp_defaultTableCellFont;
        [self addSubview:_titleLabel];
        
        _arrowLabel = [UILabel new];
        _arrowLabel.font = UIFont.dsp_defaultTableCellFont;
        [self addSubview:_arrowLabel];
        
        _lineView = [UIView new];
        _lineView.backgroundColor = DSPColor.hairlineColor;
        [self addSubview:_lineView];
        
    }
    return self;
}

- (void)setSortType:(DSPTableColumnHeaderSortType)type {
    _sortType = type;
    
    switch (type) {
        case DSPTableColumnHeaderSortTypeNone:
            _arrowLabel.text = @"";
            break;
        case DSPTableColumnHeaderSortTypeAsc:
            _arrowLabel.text = @"⬆️";
            break;
        case DSPTableColumnHeaderSortTypeDesc:
            _arrowLabel.text = @"⬇️";
            break;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGSize size = self.frame.size;
    
    self.titleLabel.frame = CGRectMake(kMargin, 0, size.width - kArrowWidth - kMargin, size.height);
    self.arrowLabel.frame = CGRectMake(size.width - kArrowWidth, 0, kArrowWidth, size.height);
    self.lineView.frame = CGRectMake(size.width - 1, 2, DSPPointsToPixels(1), size.height - 4);
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGFloat margins = kArrowWidth - 2 * kMargin;
    size = CGSizeMake(size.width - margins, size.height);
    CGFloat width = [_titleLabel sizeThatFits:size].width + margins;
    return CGSizeMake(width, size.height);
}

@end
