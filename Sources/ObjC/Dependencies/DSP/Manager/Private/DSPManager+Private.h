#import "DSPManager.h"
#import "DSPWindow.h"

@class DSPGlobalsEntry, DSPExplorerViewController;

@interface DSPManager (Private)

@property (nonatomic, readonly) DSPWindow *explorerWindow;
@property (nonatomic, readonly) DSPExplorerViewController *explorerViewController;

/// An array of DSPGlobalsEntry objects that have been registered by the user.
@property (nonatomic, readonly) NSMutableArray<DSPGlobalsEntry *> *userGlobalEntries;
@property (nonatomic, readonly) NSMutableDictionary<NSString *, DSPCustomContentViewerFuture> *customContentTypeViewers;

@end
