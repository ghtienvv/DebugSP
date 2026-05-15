#import "DSPFilteringTableViewController.h"
@protocol DSPGlobalsTableViewControllerDelegate;

typedef NS_ENUM(NSUInteger, DSPGlobalsSectionKind) {
    DSPGlobalsSectionCustom,
    /// NSProcessInfo, Network history, system log,
    /// heap, address explorer, libraries, app classes
    DSPGlobalsSectionProcessAndEvents,
    /// Browse container, browse bundle, NSBundle.main,
    /// NSUserDefaults.standard, UIApplication,
    /// app delegate, key window, root VC, cookies
    DSPGlobalsSectionAppShortcuts,
    /// UIPasteBoard.general, UIScreen, UIDevice
    DSPGlobalsSectionMisc,
    DSPGlobalsSectionCount
};

@interface DSPGlobalsViewController : DSPFilteringTableViewController

@end
