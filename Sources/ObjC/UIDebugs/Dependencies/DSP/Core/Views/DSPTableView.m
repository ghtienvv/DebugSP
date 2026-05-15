#import "DSPTableView.h"
#import "DSPUtility.h"
#import "DSPSubtitleTableViewCell.h"
#import "DSPMultilineTableViewCell.h"
#import "DSPKeyValueTableViewCell.h"
#import "DSPCodeFontCell.h"

DSPTableViewCellReuseIdentifier const kDSPDefaultCell = @"kDSPDefaultCell";
DSPTableViewCellReuseIdentifier const kDSPDetailCell = @"kDSPDetailCell";
DSPTableViewCellReuseIdentifier const kDSPMultilineCell = @"kDSPMultilineCell";
DSPTableViewCellReuseIdentifier const kDSPMultilineDetailCell = @"kDSPMultilineDetailCell";
DSPTableViewCellReuseIdentifier const kDSPKeyValueCell = @"kDSPKeyValueCell";
DSPTableViewCellReuseIdentifier const kDSPCodeFontCell = @"kDSPCodeFontCell";

#pragma mark Private

@interface UITableView (Private)
- (CGFloat)_heightForHeaderInSection:(NSInteger)section;
- (NSString *)_titleForHeaderInSection:(NSInteger)section;
@end

@implementation DSPTableView

+ (instancetype)dspDefaultTableView {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    } else {
        return [[self alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    }
}

#pragma mark - Initialization

+ (id)groupedTableView {
    if (@available(iOS 13.0, *)) {
        return [[self alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    } else {
        return [[self alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    }
}

+ (id)plainTableView {
    return [[self alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
}

+ (id)style:(UITableViewStyle)style {
    return [[self alloc] initWithFrame:CGRectZero style:style];
}

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
    self = [super initWithFrame:frame style:style];
    if (self) {
        [self registerCells:@{
            kDSPDefaultCell : [DSPTableViewCell class],
            kDSPDetailCell : [DSPSubtitleTableViewCell class],
            kDSPMultilineCell : [DSPMultilineTableViewCell class],
            kDSPMultilineDetailCell : [DSPMultilineDetailTableViewCell class],
            kDSPKeyValueCell : [DSPKeyValueTableViewCell class],
            kDSPCodeFontCell : [DSPCodeFontCell class],
        }];
    }

    return self;
}


#pragma mark - Public

- (void)registerCells:(NSDictionary<NSString*, Class> *)registrationMapping {
    [registrationMapping enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, Class cellClass, BOOL *stop) {
        [self registerClass:cellClass forCellReuseIdentifier:identifier];
    }];
}

@end
