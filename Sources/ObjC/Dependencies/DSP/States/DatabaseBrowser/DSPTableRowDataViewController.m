#import "DSPTableRowDataViewController.h"
#import "DSPMutableListSection.h"
#import "DSPAlert.h"

@interface DSPTableRowDataViewController ()
@property (nonatomic) NSDictionary<NSString *, NSString *> *rowsByColumn;
@end

@implementation DSPTableRowDataViewController

#pragma mark - Initialization

+ (instancetype)rows:(NSDictionary<NSString *, id> *)rowData {
    DSPTableRowDataViewController *controller = [self new];
    controller.rowsByColumn = rowData;
    return controller;
}

#pragma mark - Overrides

- (NSArray<DSPTableViewSection *> *)makeSections {
    NSDictionary<NSString *, NSString *> *rowsByColumn = self.rowsByColumn;
    
    DSPMutableListSection<NSString *> *section = [DSPMutableListSection list:self.rowsByColumn.allKeys
        cellConfiguration:^(UITableViewCell *cell, NSString *column, NSInteger row) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = column;
            cell.detailTextLabel.text = rowsByColumn[column].description;
        } filterMatcher:^BOOL(NSString *filterText, NSString *column) {
            return [column localizedCaseInsensitiveContainsString:filterText] ||
                [rowsByColumn[column] localizedCaseInsensitiveContainsString:filterText];
        }
    ];
    
    section.selectionHandler = ^(UIViewController *host, NSString *column) {
        UIPasteboard.generalPasteboard.string = rowsByColumn[column].description;
        [DSPAlert makeAlert:^(DSPAlert *make) {
            make.title(@"Column Copied to Clipboard");
            make.message(rowsByColumn[column].description);
            make.button(@"Dismiss").cancelStyle();
        } showFrom:host];
    };

    return @[section];
}

@end
