#import "DSPExplorerToolbar.h"
#import "DSPExplorerToolbarItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface DSPExplorerToolbar (FWDebug)

- (DSPExplorerToolbarItem *)fwDebugFpsItem;

@end

@interface DSPExplorerToolbarItem (FWDebug)

@property (nonatomic, assign) BOOL fwDebugShowRuler;
@property (nonatomic, assign) BOOL fwDebugIsRuler;

@end

NS_ASSUME_NONNULL_END
