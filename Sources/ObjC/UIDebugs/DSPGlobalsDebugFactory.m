#import "DSPGlobalsDebugFactory.h"

#import "DSPFileBrowserController.h"
#import "DSPKeychainViewController.h"
#import "DSPNavigationController.h"
#import "DSPNetworkMITMViewController.h"
#import "DSPNetworkObserver.h"

@implementation DSPGlobalsDebugFactory

+ (void)prepareRuntime {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DSPNetworkObserver.enabled = YES;
    });
}

+ (UIViewController *)keychainViewController {
    return [DSPNavigationController withRootViewController:[DSPKeychainViewController new]];
}

+ (UIViewController *)networkHistoryViewController {
    [self prepareRuntime];
    return [DSPNavigationController withRootViewController:[DSPNetworkMITMViewController new]];
}

+ (UIViewController *)crashLogViewController {
    NSString *crashLogPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    crashLogPath = [[crashLogPath stringByAppendingPathComponent:@"FWDebug"] stringByAppendingPathComponent:@"CrashLog"];
    [NSFileManager.defaultManager createDirectoryAtPath:crashLogPath withIntermediateDirectories:YES attributes:nil error:nil];
    DSPFileBrowserController *browser = [[DSPFileBrowserController alloc] initWithPath:crashLogPath];
    return [DSPNavigationController withRootViewController:browser];
}

@end
