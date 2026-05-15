#import "DSPGlobalsViewController.h"
#import "DSPUtility.h"
#import "DSPRuntimeUtility.h"
#import "DSPObjcRuntimeViewController.h"
#import "DSPKeychainViewController.h"
#import "DSPAPNSViewController.h"
#import "DSPObjectExplorerViewController.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPLiveObjectsController.h"
#import "DSPFileBrowserController.h"
#import "DSPCookiesViewController.h"
#import "States/Globals/DSPGlobalsEntry.h"
#import "DSPManager+Private.h"
#import "DSPSystemLogViewController.h"
#import "DSPNetworkMITMViewController.h"
#import "DSPAddressExplorerCoordinator.h"
#import "DSPGlobalsSection.h"
#import "UIBarButtonItem+DSP.h"

@interface DSPGlobalsViewController ()
/// Only displayed sections of the table view; empty sections are purged from this array.
@property (nonatomic) NSArray<DSPGlobalsSection *> *sections;
/// Every section in the table view, regardless of whether or not a section is empty.
@property (nonatomic, readonly) NSArray<DSPGlobalsSection *> *allSections;
@property (nonatomic, readonly) BOOL manuallyDeselectOnAppear;
@end

@implementation DSPGlobalsViewController
@dynamic sections, allSections;

#pragma mark - Initialization

+ (NSString *)globalsTitleForSection:(DSPGlobalsSectionKind)section {
    switch (section) {
        case DSPGlobalsSectionCustom:
            return @"Custom Additions";
        case DSPGlobalsSectionProcessAndEvents:
            return @"Process and Events";
        case DSPGlobalsSectionAppShortcuts:
            return @"App Shortcuts";
        case DSPGlobalsSectionMisc:
            return @"Miscellaneous";

        default:
            @throw NSInternalInconsistencyException;
    }
}

+ (DSPGlobalsEntry *)globalsEntryForRow:(DSPGlobalsRow)row {
    switch (row) {
        case DSPGlobalsRowAppKeychainItems:
            return [DSPKeychainViewController dsp_concreteGlobalsEntry:row];
        case DSPGlobalsRowPushNotifications:
            return [DSPAPNSViewController dsp_concreteGlobalsEntry:row];
        case DSPGlobalsRowAddressInspector:
            return [DSPAddressExplorerCoordinator dsp_concreteGlobalsEntry:row];
        case DSPGlobalsRowBrowseRuntime:
            return [DSPObjcRuntimeViewController dsp_concreteGlobalsEntry:row];
        case DSPGlobalsRowLiveObjects:
            return [DSPLiveObjectsController dsp_concreteGlobalsEntry:row];
        case DSPGlobalsRowCookies:
            return [DSPCookiesViewController dsp_concreteGlobalsEntry:row];
        case DSPGlobalsRowBrowseBundle:
        case DSPGlobalsRowBrowseContainer:
            return [DSPFileBrowserController dsp_concreteGlobalsEntry:row];
        case DSPGlobalsRowSystemLog:
            return [DSPSystemLogViewController dsp_concreteGlobalsEntry:row];
        case DSPGlobalsRowNetworkHistory:
            return [DSPNetworkMITMViewController dsp_concreteGlobalsEntry:row];
        case DSPGlobalsRowKeyWindow:
        case DSPGlobalsRowRootViewController:
        case DSPGlobalsRowProcessInfo:
        case DSPGlobalsRowAppDelegate:
        case DSPGlobalsRowUserDefaults:
        case DSPGlobalsRowMainBundle:
        case DSPGlobalsRowApplication:
        case DSPGlobalsRowMainScreen:
        case DSPGlobalsRowCurrentDevice:
        case DSPGlobalsRowPasteboard:
        case DSPGlobalsRowURLSession:
        case DSPGlobalsRowURLCache:
        case DSPGlobalsRowNotificationCenter:
        case DSPGlobalsRowMenuController:
        case DSPGlobalsRowFileManager:
        case DSPGlobalsRowTimeZone:
        case DSPGlobalsRowLocale:
        case DSPGlobalsRowCalendar:
        case DSPGlobalsRowMainRunLoop:
        case DSPGlobalsRowMainThread:
        case DSPGlobalsRowOperationQueue:
            return [DSPObjectExplorerFactory dsp_concreteGlobalsEntry:row];
        
        case DSPGlobalsRowCount: break;
    }
    
    @throw [NSException
        exceptionWithName:NSInternalInconsistencyException
        reason:@"Missing globals case in switch" userInfo:nil
    ];
}

+ (NSArray<DSPGlobalsSection *> *)defaultGlobalSections {
    static NSMutableArray<DSPGlobalsSection *> *sections = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary<NSNumber *, NSArray<DSPGlobalsEntry *> *> *rowsBySection = @{
            @(DSPGlobalsSectionProcessAndEvents) : @[
                [self globalsEntryForRow:DSPGlobalsRowNetworkHistory],
                [self globalsEntryForRow:DSPGlobalsRowSystemLog],
                [self globalsEntryForRow:DSPGlobalsRowProcessInfo],
                [self globalsEntryForRow:DSPGlobalsRowLiveObjects],
                [self globalsEntryForRow:DSPGlobalsRowAddressInspector],
                [self globalsEntryForRow:DSPGlobalsRowBrowseRuntime],
            ],
            @(DSPGlobalsSectionAppShortcuts) : @[
                [self globalsEntryForRow:DSPGlobalsRowBrowseBundle],
                [self globalsEntryForRow:DSPGlobalsRowBrowseContainer],
                [self globalsEntryForRow:DSPGlobalsRowMainBundle],
                [self globalsEntryForRow:DSPGlobalsRowUserDefaults],
                [self globalsEntryForRow:DSPGlobalsRowAppKeychainItems],
                [self globalsEntryForRow:DSPGlobalsRowPushNotifications],
                [self globalsEntryForRow:DSPGlobalsRowApplication],
                [self globalsEntryForRow:DSPGlobalsRowAppDelegate],
                [self globalsEntryForRow:DSPGlobalsRowKeyWindow],
                [self globalsEntryForRow:DSPGlobalsRowRootViewController],
                [self globalsEntryForRow:DSPGlobalsRowCookies],
            ],
            @(DSPGlobalsSectionMisc) : @[
                [self globalsEntryForRow:DSPGlobalsRowPasteboard],
                [self globalsEntryForRow:DSPGlobalsRowMainScreen],
                [self globalsEntryForRow:DSPGlobalsRowCurrentDevice],
                [self globalsEntryForRow:DSPGlobalsRowURLSession],
                [self globalsEntryForRow:DSPGlobalsRowURLCache],
                [self globalsEntryForRow:DSPGlobalsRowNotificationCenter],
                [self globalsEntryForRow:DSPGlobalsRowMenuController],
                [self globalsEntryForRow:DSPGlobalsRowFileManager],
                [self globalsEntryForRow:DSPGlobalsRowTimeZone],
                [self globalsEntryForRow:DSPGlobalsRowLocale],
                [self globalsEntryForRow:DSPGlobalsRowCalendar],
                [self globalsEntryForRow:DSPGlobalsRowMainRunLoop],
                [self globalsEntryForRow:DSPGlobalsRowMainThread],
                [self globalsEntryForRow:DSPGlobalsRowOperationQueue],
            ]
        };

        sections = [NSMutableArray array];
        for (DSPGlobalsSectionKind i = DSPGlobalsSectionCustom + 1; i < DSPGlobalsSectionCount; ++i) {
            NSString *title = [self globalsTitleForSection:i];
            [sections addObject:[DSPGlobalsSection title:title rows:rowsBySection[@(i)]]];
        }
    });
    
    return sections;
}


#pragma mark - Overrides

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"💪  DSP";
    self.showsSearchBar = YES;
    self.searchBarDebounceInterval = kDSPDebounceInstant;
    self.navigationItem.backBarButtonItem = [UIBarButtonItem dsp_backItemWithTitle:@"Back"];
    
    _manuallyDeselectOnAppear = NSProcessInfo.processInfo.operatingSystemVersion.majorVersion < 10;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self disableToolbar];
    
    if (self.manuallyDeselectOnAppear) {
        [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    }
}

- (NSArray<DSPGlobalsSection *> *)makeSections {
    NSMutableArray<DSPGlobalsSection *> *sections = [NSMutableArray array];
    // Do we have custom sections to add?
    if (DSPManager.sharedManager.userGlobalEntries.count) {
        NSString *title = [[self class] globalsTitleForSection:DSPGlobalsSectionCustom];
        DSPGlobalsSection *custom = [DSPGlobalsSection
            title:title
            rows:DSPManager.sharedManager.userGlobalEntries
        ];
        [sections addObject:custom];
    }

    [sections addObjectsFromArray:[self.class defaultGlobalSections]];

    return sections;
}

@end
