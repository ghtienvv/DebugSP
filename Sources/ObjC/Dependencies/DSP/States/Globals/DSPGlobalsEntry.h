#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, DSPGlobalsRow) {
    DSPGlobalsRowProcessInfo,
    DSPGlobalsRowNetworkHistory,
    DSPGlobalsRowSystemLog,
    DSPGlobalsRowLiveObjects,
    DSPGlobalsRowAddressInspector,
    DSPGlobalsRowCookies,
    DSPGlobalsRowBrowseRuntime,
    DSPGlobalsRowAppKeychainItems,
    DSPGlobalsRowPushNotifications,
    DSPGlobalsRowAppDelegate,
    DSPGlobalsRowRootViewController,
    DSPGlobalsRowUserDefaults,
    DSPGlobalsRowMainBundle,
    DSPGlobalsRowBrowseBundle,
    DSPGlobalsRowBrowseContainer,
    DSPGlobalsRowApplication,
    DSPGlobalsRowKeyWindow,
    DSPGlobalsRowMainScreen,
    DSPGlobalsRowCurrentDevice,
    DSPGlobalsRowPasteboard,
    DSPGlobalsRowURLSession,
    DSPGlobalsRowURLCache,
    DSPGlobalsRowNotificationCenter,
    DSPGlobalsRowMenuController,
    DSPGlobalsRowFileManager,
    DSPGlobalsRowTimeZone,
    DSPGlobalsRowLocale,
    DSPGlobalsRowCalendar,
    DSPGlobalsRowMainRunLoop,
    DSPGlobalsRowMainThread,
    DSPGlobalsRowOperationQueue,
    DSPGlobalsRowCount
};

typedef NSString * _Nonnull (^DSPGlobalsEntryNameFuture)(void);
/// Simply return a view controller to be pushed on the navigation stack
typedef UIViewController * _Nullable (^DSPGlobalsEntryViewControllerFuture)(void);
/// Do something like present an alert, then use the host
/// view controller to present or push another view controller.
typedef void (^DSPGlobalsEntryRowAction)(__kindof UITableViewController * _Nonnull host);

/// For view controllers to conform to to indicate they support being used
/// in the globals table view controller. These methods help create concrete entries.
///
/// Previously, the concrete entries relied on "futures" for the view controller and title.
/// With this protocol, the conforming class itself can act as a future, since the methods
/// will not be invoked until the title and view controller / row action are needed.
///
/// Entries can implement \c globalsEntryViewController: to unconditionally provide a
/// view controller, or \c globalsEntryRowAction: to conditionally provide one and
/// perform some action (such as present an alert) if no view controller is available,
/// or both if there is a mix of rows where some are guaranteed to work and some are not.
/// Where both are implemented, \c globalsEntryRowAction: takes precedence; if it returns
/// an action for the requested row, that will be used instead of \c globalsEntryViewController:
@protocol DSPGlobalsEntry <NSObject>

+ (NSString *)globalsEntryTitle:(DSPGlobalsRow)row;

// Must respond to at least one of the below.
// globalsEntryRowAction: takes precedence if both are implemented.
@optional

+ (nullable UIViewController *)globalsEntryViewController:(DSPGlobalsRow)row;
+ (nullable DSPGlobalsEntryRowAction)globalsEntryRowAction:(DSPGlobalsRow)row;

@end

@interface DSPGlobalsEntry : NSObject

@property (nonatomic, readonly, nonnull)  DSPGlobalsEntryNameFuture entryNameFuture;
@property (nonatomic, readonly, nullable) DSPGlobalsEntryViewControllerFuture viewControllerFuture;
@property (nonatomic, readonly, nullable) DSPGlobalsEntryRowAction rowAction;

+ (instancetype)entryWithEntry:(Class<DSPGlobalsEntry>)entry row:(DSPGlobalsRow)row;

+ (instancetype)entryWithNameFuture:(DSPGlobalsEntryNameFuture)nameFuture
               viewControllerFuture:(DSPGlobalsEntryViewControllerFuture)viewControllerFuture;

+ (instancetype)entryWithNameFuture:(DSPGlobalsEntryNameFuture)nameFuture
                             action:(DSPGlobalsEntryRowAction)rowSelectedAction;

@end


@interface NSObject (DSPGlobalsEntry)

/// @return The result of passing self to +[DSPGlobalsEntry entryWithEntry:]
/// if the class conforms to DSPGlobalsEntry, else, nil.
+ (nullable DSPGlobalsEntry *)dsp_concreteGlobalsEntry:(DSPGlobalsRow)row;

@end

NS_ASSUME_NONNULL_END
