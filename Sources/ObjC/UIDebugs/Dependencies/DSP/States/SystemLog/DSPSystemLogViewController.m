#import "DSPSystemLogViewController.h"
#import "DSPASLLogController.h"
#import "DSPOSLogController.h"
#import "DSPSystemLogCell.h"
#import "DSPMutableListSection.h"
#import "DSPUtility.h"
#import "DSPColor.h"
#import "DSPResources.h"
#import "UIBarButtonItem+DSP.h"
#import "NSUserDefaults+DSP.h"
#import "DSP_fishhook.h"
#import <dlfcn.h>

@interface DSPSystemLogViewController ()

@property (nonatomic, readonly) DSPMutableListSection<DSPSystemLogMessage *> *logMessages;
@property (nonatomic, readonly) id<DSPLogController> logController;

@end

static void (*MSHookFunction)(void *symbol, void *replace, void **result);

static BOOL DSPDidHookNSLog = NO;
static BOOL DSPNSLogHookWorks = NO;

BOOL (*os_log_shim_enabled)(void *addr) = nil;
BOOL (*orig_os_log_shim_enabled)(void *addr) = nil;
static BOOL my_os_log_shim_enabled(void *addr) {
    return NO;
}

@implementation DSPSystemLogViewController

#pragma mark - Initialization

+ (void)load {
    // User must opt-into disabling os_log
    if (!NSUserDefaults.standardUserDefaults.dsp_disableOSLog) {
        return;
    }

    // Thanks to @Ram4096 on GitHub for telling me that
    // os_log is conditionally enabled by the SDK version
    void *addr = __builtin_return_address(0);
    void *libsystem_trace = dlopen("/usr/lib/system/libsystem_trace.dylib", RTLD_LAZY);
    os_log_shim_enabled = dlsym(libsystem_trace, "os_log_shim_enabled");
    if (!os_log_shim_enabled) {
        return;
    }

    DSPDidHookNSLog = dsp_rebind_symbols((struct rebinding[1]) {{
        "os_log_shim_enabled",
        (void *)my_os_log_shim_enabled,
        (void **)&orig_os_log_shim_enabled
    }}, 1) == 0;

    if (DSPDidHookNSLog && orig_os_log_shim_enabled != nil) {
        // Check if our rebinding worked
        DSPNSLogHookWorks = my_os_log_shim_enabled(addr) == NO;
    }

    // So, just because we rebind the lazily loaded symbol for
    // this function doesn't mean it's even going to be used.
    // While it seems to be sufficient for the simulator, for
    // whatever reason it is not sufficient on-device. We need
    // to actually hook the function with something like Substrate.

    // Check if we have substrate, and if so use that instead
    void *handle = dlopen("/usr/lib/libsubstrate.dylib", RTLD_LAZY);
    if (handle) {
        MSHookFunction = dlsym(handle, "MSHookFunction");

        if (MSHookFunction) {
            // Set the hook and check if it worked
            void *unused;
            MSHookFunction(os_log_shim_enabled, my_os_log_shim_enabled, &unused);
            DSPNSLogHookWorks = os_log_shim_enabled(addr) == NO;
        }
    }
}

- (id)init {
    return [super initWithStyle:UITableViewStylePlain];
}


#pragma mark - Overrides

- (void)viewDidLoad {
    [super viewDidLoad];

    self.showsSearchBar = YES;
    self.pinSearchBar = YES;

    weakify(self)
    id logHandler = ^(NSArray<DSPSystemLogMessage *> *newMessages) { strongify(self)
        [self handleUpdateWithNewMessages:newMessages];
    };

    if (DSPOSLogAvailable() && !DSPNSLogHookWorks) {
        _logController = [DSPOSLogController withUpdateHandler:logHandler];
    } else {
        _logController = [DSPASLLogController withUpdateHandler:logHandler];
    }

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.title = @"Waiting for Logs...";

    // Toolbar buttons //

    UIBarButtonItem *scrollDown = [UIBarButtonItem
        dsp_itemWithImage:DSPResources.scrollToBottomIcon
        target:self
        action:@selector(scrollToLastRow)
    ];
    UIBarButtonItem *settings = [UIBarButtonItem
        dsp_itemWithImage:DSPResources.gearIcon
        target:self
        action:@selector(showLogSettings)
    ];

    [self addToolbarItems:@[scrollDown, settings]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.logController startMonitoring];
}

- (NSArray<DSPTableViewSection *> *)makeSections { weakify(self)
    _logMessages = [DSPMutableListSection list:@[]
        cellConfiguration:^(DSPSystemLogCell *cell, DSPSystemLogMessage *message, NSInteger row) {
            strongify(self)
        
            cell.logMessage = message;
            cell.highlightedText = self.filterText;

            if (row % 2 == 0) {
                cell.backgroundColor = DSPColor.primaryBackgroundColor;
            } else {
                cell.backgroundColor = DSPColor.secondaryBackgroundColor;
            }
        } filterMatcher:^BOOL(NSString *filterText, DSPSystemLogMessage *message) {
            NSString *displayedText = [DSPSystemLogCell displayedTextForLogMessage:message];
            return [displayedText localizedCaseInsensitiveContainsString:filterText];
        }
    ];

    self.logMessages.cellRegistrationMapping = @{
        kDSPSystemLogCellIdentifier : [DSPSystemLogCell class]
    };

    return @[self.logMessages];
}

- (NSArray<DSPTableViewSection *> *)nonemptySections {
    return @[self.logMessages];
}


#pragma mark - Private

- (void)handleUpdateWithNewMessages:(NSArray<DSPSystemLogMessage *> *)newMessages {
    self.title = [self.class globalsEntryTitle:DSPGlobalsRowSystemLog];

    [self.logMessages mutate:^(NSMutableArray *list) {
        [list addObjectsFromArray:newMessages];
    }];
    
    // Re-filter messages to filter against new messages
    if (self.filterText.length) {
        [self updateSearchResults:self.filterText];
    }

    // "Follow" the log as new messages stream in if we were previously near the bottom.
    UITableView *tv = self.tableView;
    BOOL wasNearBottom = tv.contentOffset.y >= tv.contentSize.height - tv.frame.size.height - 100.0;
    [self reloadData];
    if (wasNearBottom) {
        [self scrollToLastRow];
    }
}

- (void)scrollToLastRow {
    NSInteger numberOfRows = [self.tableView numberOfRowsInSection:0];
    if (numberOfRows > 0) {
        NSIndexPath *last = [NSIndexPath indexPathForRow:numberOfRows - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)showLogSettings {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL disableOSLog = defaults.dsp_disableOSLog;
    BOOL persistent = defaults.dsp_cacheOSLogMessages;

    NSString *aslToggle = disableOSLog ? @"Enable os_log (default)" : @"Disable os_log";
    NSString *persistence = persistent ? @"Disable persistent logging" : @"Enable persistent logging";

    NSString *title = @"System Log Settings";
    NSString *body = @"In iOS 10 and up, ASL has been replaced by os_log. "
    "The os_log API is much more limited. Below, you can opt-into the old behavior "
    "if you want cleaner, more reliable logs within DSP, but this will break "
    "anything that expects os_log to be working, such as Console.app. "
    "This setting requires the app to restart to take effect. \n\n"

    "To get as close to the old behavior as possible with os_log enabled, logs must "
    "be collected manually at launch and stored. This setting has no effect "
    "on iOS 9 and below, or if os_log is disabled. "
    "You should only enable persistent logging when you need it.";

    DSPOSLogController *logController = (DSPOSLogController *)self.logController;

    [DSPAlert makeAlert:^(DSPAlert *make) {
        make.title(title).message(body);
        make.button(aslToggle).destructiveStyle().handler(^(NSArray<NSString *> *strings) {
            [defaults dsp_toggleBoolForKey:kDSPDefaultsDisableOSLogForceASLKey];
        });

        make.button(persistence).handler(^(NSArray<NSString *> *strings) {
            [defaults dsp_toggleBoolForKey:kDSPDefaultsPersistentOSLogKey];
            logController.persistent = !persistent;
            [logController.messages addObjectsFromArray:self.logMessages.list];
        });
        make.button(@"Dismiss").cancelStyle();
    } showFrom:self];
}


#pragma mark - DSPGlobalsEntry

+ (NSString *)globalsEntryTitle:(DSPGlobalsRow)row {
    return @"⚠️  System Log";
}

+ (UIViewController *)globalsEntryViewController:(DSPGlobalsRow)row {
    return [self new];
}


#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    DSPSystemLogMessage *logMessage = self.logMessages.filteredList[indexPath.row];
    return [DSPSystemLogCell preferredHeightForLogMessage:logMessage inWidth:self.tableView.bounds.size.width];
}


#pragma mark - Copy on long press

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    return action == @selector(copy:);
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    if (action == @selector(copy:)) {
        // We usually only want to copy the log message itself, not any metadata associated with it.
        UIPasteboard.generalPasteboard.string = self.logMessages.filteredList[indexPath.row].messageText ?: @"";
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView
contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
                                    point:(CGPoint)point __IOS_AVAILABLE(13.0) {
    weakify(self)
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil
        actionProvider:^UIMenu *(NSArray<UIMenuElement *> *suggestedActions) {
            UIAction *copy = [UIAction actionWithTitle:@"Copy"
                                                 image:nil
                                            identifier:@"Copy"
                                               handler:^(UIAction *action) { strongify(self)
                // We usually only want to copy the log message itself, not any metadata associated with it.
                UIPasteboard.generalPasteboard.string = self.logMessages.filteredList[indexPath.row].messageText ?: @"";
            }];
            return [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[copy]];
        }
    ];
}

@end
