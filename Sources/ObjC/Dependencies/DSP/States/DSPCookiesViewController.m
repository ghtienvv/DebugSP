#import "DSPCookiesViewController.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPMutableListSection.h"
#import "DSPUtility.h"

@interface DSPCookiesViewController ()
@property (nonatomic, readonly) DSPMutableListSection<NSHTTPCookie *> *cookies;
@property (nonatomic) NSString *headerTitle;
@end

@implementation DSPCookiesViewController

#pragma mark - Overrides

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Cookies";
}

- (NSString *)headerTitle {
    return self.cookies.title;
}

- (void)setHeaderTitle:(NSString *)headerTitle {
    self.cookies.customTitle = headerTitle;
}

- (NSArray<DSPTableViewSection *> *)makeSections {
    NSSortDescriptor *nameSortDescriptor = [[NSSortDescriptor alloc]
        initWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)
    ];
    NSArray *cookies = [NSHTTPCookieStorage.sharedHTTPCookieStorage.cookies
       sortedArrayUsingDescriptors:@[nameSortDescriptor]
    ];
    
    _cookies = [DSPMutableListSection list:cookies
        cellConfiguration:^(UITableViewCell *cell, NSHTTPCookie *cookie, NSInteger row) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = [cookie.name stringByAppendingFormat:@" (%@)", cookie.value];
            cell.detailTextLabel.text = [cookie.domain stringByAppendingFormat:@" — %@", cookie.path];
        } filterMatcher:^BOOL(NSString *filterText, NSHTTPCookie *cookie) {
            return [cookie.name localizedCaseInsensitiveContainsString:filterText] ||
                [cookie.value localizedCaseInsensitiveContainsString:filterText] ||
                [cookie.domain localizedCaseInsensitiveContainsString:filterText] ||
                [cookie.path localizedCaseInsensitiveContainsString:filterText];
        }
    ];
    
    self.cookies.selectionHandler = ^(UIViewController *host, NSHTTPCookie *cookie) {
        [host.navigationController pushViewController:[
            DSPObjectExplorerFactory explorerViewControllerForObject:cookie
        ] animated:YES];
    };
    
    return @[self.cookies];
}

- (void)reloadData {
    self.headerTitle = [NSString stringWithFormat:
        @"%@ cookies", @(self.cookies.filteredList.count)
    ];
    [super reloadData];
}

#pragma mark - DSPGlobalsEntry

+ (NSString *)globalsEntryTitle:(DSPGlobalsRow)row {
    return @"🍪  Cookies";
}

+ (UIViewController *)globalsEntryViewController:(DSPGlobalsRow)row {
    return [self new];
}

@end
