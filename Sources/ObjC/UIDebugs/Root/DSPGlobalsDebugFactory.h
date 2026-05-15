#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DSPGlobalsDebugFactory : NSObject

+ (void)prepareRuntime;
+ (UIViewController *)keychainViewController;
+ (UIViewController *)networkHistoryViewController;
+ (UIViewController *)crashLogViewController;

@end

NS_ASSUME_NONNULL_END