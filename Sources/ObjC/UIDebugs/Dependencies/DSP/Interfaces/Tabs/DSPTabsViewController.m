#import "DSPTabsViewController.h"
#import "DSPNavigationController.h"
#import "DSPTabList.h"
#import "DSPBookmarkManager.h"
#import "DSPTableView.h"
#import "DSPUtility.h"
#import "DSPColor.h"
#import "UIBarButtonItem+DSP.h"
#import "DSPExplorerViewController.h"
#import "DSPGlobalsViewController.h"
#import "DSPBookmarksViewController.h"

@interface DSPTabsViewController ()
@property (nonatomic, copy) NSArray<UINavigationController *> *openTabs;
@property (nonatomic, copy) NSArray<UIImage *> *tabSnapshots;
@property (nonatomic) NSInteger activeIndex;
@property (nonatomic) BOOL presentNewActiveTabOnDismiss;

@property (nonatomic, readonly) DSPExplorerViewController *corePresenter;
@end

@implementation DSPTabsViewController

#pragma mark - Initialization

- (id)init {
    return [self initWithStyle:UITableViewStylePlain];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Open Tabs";
    self.navigationController.hidesBarsOnSwipe = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    [self reloadData:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupDefaultBarItems];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Instead of updating the active snapshot before we present,
    // we update it after we present to avoid pre-presenation latency
    dispatch_async(dispatch_get_main_queue(), ^{
        [DSPTabList.sharedList updateSnapshotForActiveTab];
        [self reloadData:NO];
        [self.tableView reloadData];
    });
}


#pragma mark - Private

/// @param trackActiveTabDelta whether to check if the active
/// tab changed and needs to be presented upon "Done" dismissal.
/// @return whether the active tab changed or not (if there are any tabs left)
- (BOOL)reloadData:(BOOL)trackActiveTabDelta {
    BOOL activeTabDidChange = NO;
    DSPTabList *list = DSPTabList.sharedList;
    
    // Flag to enable check to determine whether
    if (trackActiveTabDelta) {
        NSInteger oldActiveIndex = self.activeIndex;
        if (oldActiveIndex != list.activeTabIndex && list.activeTabIndex != NSNotFound) {
            self.presentNewActiveTabOnDismiss = YES;
            activeTabDidChange = YES;
        } else if (self.presentNewActiveTabOnDismiss) {
            // If we had something to present before, now we don't
            // (i.e. activeTabIndex == NSNotFound)
            self.presentNewActiveTabOnDismiss = NO;
        }
    }
    
    // We assume the tabs aren't going to change out from under us, since
    // presenting any other tool via keyboard shortcuts should dismiss us first
    self.openTabs = list.openTabs;
    self.tabSnapshots = list.openTabSnapshots;
    self.activeIndex = list.activeTabIndex;
    
    return activeTabDidChange;
}

- (void)reloadActiveTabRowIfChanged:(BOOL)activeTabChanged {
    // Refresh the newly active tab row if needed
    if (activeTabChanged) {
        NSIndexPath *active = [NSIndexPath
           indexPathForRow:self.activeIndex inSection:0
        ];
        [self.tableView reloadRowsAtIndexPaths:@[active] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)setupDefaultBarItems {
    self.navigationItem.rightBarButtonItem = DSPBarButtonItemSystem(Done, self, @selector(dismissAnimated));
    self.toolbarItems = @[
        UIBarButtonItem.dsp_fixedSpace,
        UIBarButtonItem.dsp_dspibleSpace,
        DSPBarButtonItemSystem(Add, self, @selector(addTabButtonPressed:)),
        UIBarButtonItem.dsp_dspibleSpace,
        DSPBarButtonItemSystem(Edit, self, @selector(toggleEditing)),
    ];
    
    // Disable editing if no tabs available
    self.toolbarItems.lastObject.enabled = self.openTabs.count > 0;
}

- (void)setupEditingBarItems {
    self.navigationItem.rightBarButtonItem = nil;
    self.toolbarItems = @[
        [UIBarButtonItem dsp_itemWithTitle:@"Close All" target:self action:@selector(closeAllButtonPressed:)],
        UIBarButtonItem.dsp_dspibleSpace,
        [UIBarButtonItem dsp_disabledSystemItem:UIBarButtonSystemItemAdd],
        UIBarButtonItem.dsp_dspibleSpace,
        // We use a non-system done item because we change its title dynamically
        [UIBarButtonItem dsp_doneStyleitemWithTitle:@"Done" target:self action:@selector(toggleEditing)]
    ];
    
    self.toolbarItems.firstObject.tintColor = DSPColor.destructiveColor;
}

- (DSPExplorerViewController *)corePresenter {
    // We must be presented by a DSPExplorerViewController, or presented
    // by another view controller that was presented by DSPExplorerViewController
    DSPExplorerViewController *presenter = (id)self.presentingViewController;
    presenter = (id)presenter.presentingViewController ?: presenter;
    NSAssert(
        [presenter isKindOfClass:[DSPExplorerViewController class]],
        @"The tabs view controller expects to be presented by the explorer controller"
    );
    return presenter;
}


#pragma mark Button Actions

- (void)dismissAnimated {
    if (self.presentNewActiveTabOnDismiss) {
        // The active tab was closed so we need to present the new one
        UIViewController *activeTab = DSPTabList.sharedList.activeTab;
        DSPExplorerViewController *presenter = self.corePresenter;
        [presenter dismissViewControllerAnimated:YES completion:^{
            [presenter presentViewController:activeTab animated:YES completion:nil];
        }];
    } else if (self.activeIndex == NSNotFound) {
        // The only tab was closed, so dismiss everything
        [self.corePresenter dismissViewControllerAnimated:YES completion:nil];
    } else {
        // Simple dismiss with the same active tab, only dismiss myself
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)toggleEditing {
    NSArray<NSIndexPath *> *selected = self.tableView.indexPathsForSelectedRows;
    self.editing = !self.editing;
    
    if (self.isEditing) {
        [self setupEditingBarItems];
    } else {
        [self setupDefaultBarItems];
        
        // Get index set of tabs to close
        NSMutableIndexSet *indexes = [NSMutableIndexSet new];
        for (NSIndexPath *ip in selected) {
            [indexes addIndex:ip.row];
        }
        
        if (selected.count) {
            // Close tabs and update data source
            [DSPTabList.sharedList closeTabsAtIndexes:indexes];
            BOOL activeTabChanged = [self reloadData:YES];
            
            // Remove deleted rows
            [self.tableView deleteRowsAtIndexPaths:selected withRowAnimation:UITableViewRowAnimationAutomatic];
            
            // Refresh the newly active tab row if needed
            [self reloadActiveTabRowIfChanged:activeTabChanged];
        }
    }
}

- (void)addTabButtonPressed:(UIBarButtonItem *)sender {
    if (DSPBookmarkManager.bookmarks.count) {
        [DSPAlert makeSheet:^(DSPAlert *make) {
            make.title(@"New Tab");
            make.button(@"Main Menu").handler(^(NSArray<NSString *> *strings) {
                [self addTabAndDismiss:[DSPNavigationController
                    withRootViewController:[DSPGlobalsViewController new]
                ]];
            });
            make.button(@"Choose from Bookmarks").handler(^(NSArray<NSString *> *strings) {
                [self presentViewController:[DSPNavigationController
                    withRootViewController:[DSPBookmarksViewController new]
                ] animated:YES completion:nil];
            });
            make.button(@"Cancel").cancelStyle();
        } showFrom:self source:sender];
    } else {
        // No bookmarks, just open the main menu
        [self addTabAndDismiss:[DSPNavigationController
            withRootViewController:[DSPGlobalsViewController new]
        ]];
    }
}

- (void)addTabAndDismiss:(UINavigationController *)newTab {
    DSPExplorerViewController *presenter = self.corePresenter;
    [presenter dismissViewControllerAnimated:YES completion:^{
        [presenter presentViewController:newTab animated:YES completion:nil];
    }];
}

- (void)closeAllButtonPressed:(UIBarButtonItem *)sender {
    [DSPAlert makeSheet:^(DSPAlert *make) {
        NSInteger count = self.openTabs.count;
        NSString *title = DSPPluralFormatString(count, @"Close %@ tabs", @"Close %@ tab");
        make.button(title).destructiveStyle().handler(^(NSArray<NSString *> *strings) {
            [self closeAll];
            [self toggleEditing];
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self source:sender];
}

- (void)closeAll {
    NSInteger rowCount = self.openTabs.count;
    
    // Close tabs and update data source
    [DSPTabList.sharedList closeAllTabs];
    [self reloadData:YES];
    
    // Delete rows from table view
    NSArray<NSIndexPath *> *allRows = [NSArray dsp_forEachUpTo:rowCount map:^id(NSUInteger row) {
        return [NSIndexPath indexPathForRow:row inSection:0];
    }];
    [self.tableView deleteRowsAtIndexPaths:allRows withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.openTabs.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kDSPDetailCell forIndexPath:indexPath];
    
    UINavigationController *tab = self.openTabs[indexPath.row];
    cell.imageView.image = self.tabSnapshots[indexPath.row];
    cell.textLabel.text = tab.topViewController.title;
    cell.detailTextLabel.text = DSPPluralString(tab.viewControllers.count, @"pages", @"page");
    
    if (!cell.tag) {
        cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        cell.tag = 1;
    }
    
    if (indexPath.row == self.activeIndex) {
        cell.backgroundColor = DSPColor.secondaryBackgroundColor;
    } else {
        cell.backgroundColor = DSPColor.primaryBackgroundColor;
    }
    
    return cell;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.editing) {
        // Case: editing with multi-select
        self.toolbarItems.lastObject.title = @"Close Selected";
        self.toolbarItems.lastObject.tintColor = DSPColor.destructiveColor;
    } else {
        if (self.activeIndex == indexPath.row && self.corePresenter != self.presentingViewController) {
            // Case: selected the already active tab
            [self dismissAnimated];
        } else {
            // Case: selected a different tab,
            // or selected a tab when presented from the DSP toolbar
            DSPTabList.sharedList.activeTabIndex = indexPath.row;
            self.presentNewActiveTabOnDismiss = YES;
            [self dismissAnimated];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(self.editing);
    
    if (tableView.indexPathsForSelectedRows.count == 0) {
        self.toolbarItems.lastObject.title = @"Done";
        self.toolbarItems.lastObject.tintColor = self.view.tintColor;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)table
commitEditingStyle:(UITableViewCellEditingStyle)edit
forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(edit == UITableViewCellEditingStyleDelete);
    
    // Close tab and update data source
    [DSPTabList.sharedList closeTab:self.openTabs[indexPath.row]];
    BOOL activeTabChanged = [self reloadData:YES];
    
    // Delete row from table view
    [table deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    // Refresh the newly active tab row if needed
    [self reloadActiveTabRowIfChanged:activeTabChanged];
}

@end
