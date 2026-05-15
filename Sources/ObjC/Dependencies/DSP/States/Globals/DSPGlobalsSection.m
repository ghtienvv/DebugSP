#import "DSPGlobalsSection.h"
#import "NSArray+DSP.h"
#import "UIFont+DSP.h"

@interface DSPGlobalsSection ()
/// Filtered rows
@property (nonatomic) NSArray<DSPGlobalsEntry *> *rows;
/// Unfiltered rows
@property (nonatomic) NSArray<DSPGlobalsEntry *> *allRows;
@end
@implementation DSPGlobalsSection

#pragma mark - Initialization

+ (instancetype)title:(NSString *)title rows:(NSArray<DSPGlobalsEntry *> *)rows {
    DSPGlobalsSection *s = [self new];
    s->_title = title;
    s.allRows = rows;

    return s;
}

- (void)setAllRows:(NSArray<DSPGlobalsEntry *> *)allRows {
    _allRows = allRows.copy;
    [self reloadData];
}

#pragma mark - Overrides

- (NSInteger)numberOfRows {
    return self.rows.count;
}

- (void)setFilterText:(NSString *)filterText {
    super.filterText = filterText;
    [self reloadData];
}

- (void)reloadData {
    NSString *filterText = self.filterText;
    
    if (filterText.length) {
        self.rows = [self.allRows dsp_filtered:^BOOL(DSPGlobalsEntry *entry, NSUInteger idx) {
            return [entry.entryNameFuture() localizedCaseInsensitiveContainsString:filterText];
        }];
    } else {
        self.rows = self.allRows;
    }
}

- (BOOL)canSelectRow:(NSInteger)row {
    return YES;
}

- (void (^)(__kindof UIViewController *))didSelectRowAction:(NSInteger)row {
    return (id)self.rows[row].rowAction;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    return self.rows[row].viewControllerFuture ? self.rows[row].viewControllerFuture() : nil;
}

- (void)configureCell:(__kindof UITableViewCell *)cell forRow:(NSInteger)row {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.font = UIFont.dsp_defaultTableCellFont;
    cell.textLabel.text = self.rows[row].entryNameFuture();
}

@end


@implementation DSPGlobalsSection (Subscripting)

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
    return self.rows[idx];
}

@end
