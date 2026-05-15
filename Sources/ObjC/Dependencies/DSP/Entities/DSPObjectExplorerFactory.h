#import "States/Globals/DSPGlobalsEntry.h"

#ifndef _DSPObjectExplorerViewController_h
#import "DSPObjectExplorerViewController.h"
#else
@class DSPObjectExplorerViewController;
#endif

NS_ASSUME_NONNULL_BEGIN

@interface DSPObjectExplorerFactory : NSObject <DSPGlobalsEntry>

+ (nullable DSPObjectExplorerViewController *)explorerViewControllerForObject:(nullable id)object;

/// Register a specific explorer view controller class to be used when exploring
/// an object of a specific class. Calls will overwrite existing registrations.
/// Sections must be initialized using \c forObject: like
+ (void)registerExplorerSection:(Class)sectionClass forClass:(Class)objectClass;

@end

NS_ASSUME_NONNULL_END
