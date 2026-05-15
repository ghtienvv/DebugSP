#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DSPUIDebugManager : NSObject

@property (class, nonatomic, readonly) DSPUIDebugManager *sharedManager;
@property (nonatomic, readonly, getter=isVisible) BOOL visible;

- (void)showMenu;
- (void)hideMenu;
- (void)showSelectionExplorer;

@end

NS_ASSUME_NONNULL_END
