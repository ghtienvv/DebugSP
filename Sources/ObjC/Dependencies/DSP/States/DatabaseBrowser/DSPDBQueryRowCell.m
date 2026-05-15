#import "DSPDBQueryRowCell.h"
#import "DSPMultiColumnTableView.h"
#import "NSArray+DSP.h"
#import "UIFont+DSP.h"
#import "DSPColor.h"

NSString * const kDSPDBQueryRowCellReuseIdentifier = @"kDSPDBQueryRowCellReuse";
NSString * const kDSPDBQueryRowCellReuse = @"kDSPDBQueryRowCellReuse";

@interface DSPDBQueryRowCell ()
@property (nonatomic) NSInteger columnCount;
@property (nonatomic) NSArray<UILabel *> *labels;
@end

@implementation DSPDBQueryRowCell

- (void)setData:(NSArray *)data {
    _data = data;
    self.columnCount = data.count;
    
    [self.labels dsp_forEach:^(UILabel *label, NSUInteger idx) {
        id content = self.data[idx];
        
        if ([content isKindOfClass:[NSString class]]) {
            label.text = content;
        } else if (content == NSNull.null) {
            label.text = @"<null>";
            label.textColor = DSPColor.deemphasizedTextColor;
        } else {
            label.text = [content description];
        }
    }];
}

- (void)setColumnCount:(NSInteger)columnCount {
    if (columnCount != _columnCount) {
        _columnCount = columnCount;
        
        // Remove existing labels
        for (UILabel *l in self.labels) {
            [l removeFromSuperview];
        }
        
        // Create new labels
        self.labels = [NSArray dsp_forEachUpTo:columnCount map:^id(NSUInteger i) {
            UILabel *label = [UILabel new];
            label.font = UIFont.dsp_defaultTableCellFont;
            label.textAlignment = NSTextAlignmentLeft;
            [self.contentView addSubview:label];
            
            return label;
        }];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat height = self.contentView.frame.size.height;
    
    [self.labels dsp_forEach:^(UILabel *label, NSUInteger i) {
        CGFloat width = [self.layoutSource dbQueryRowCell:self widthForColumn:i];
        CGFloat minX = [self.layoutSource dbQueryRowCell:self minXForColumn:i];
        label.frame = CGRectMake(minX + 5, 0, (width - 10), height);
    }];
}

@end
