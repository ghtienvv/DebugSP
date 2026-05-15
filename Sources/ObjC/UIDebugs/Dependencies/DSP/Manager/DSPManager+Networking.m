#import "DSPManager+Networking.h"
#import "DSPManager+Private.h"
#import "DSPNetworkObserver.h"
#import "DSPNetworkRecorder.h"
#import "DSPObjectExplorerFactory.h"
#import "NSUserDefaults+DSP.h"

@implementation DSPManager (Networking)

+ (void)load {
    if (NSUserDefaults.standardUserDefaults.dsp_registerDictionaryJSONViewerOnLaunch) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // Register array/dictionary viewer for JSON responses
            [self.sharedManager setCustomViewerForContentType:@"application/json"
                viewControllerFutureBlock:^UIViewController *(NSData *data) {
                    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                    if (jsonObject) {
                        return [DSPObjectExplorerFactory explorerViewControllerForObject:jsonObject];
                    }
                    return nil;
                }
            ];
        });
    }
}

- (BOOL)isNetworkDebuggingEnabled {
    return DSPNetworkObserver.isEnabled;
}

- (void)setNetworkDebuggingEnabled:(BOOL)networkDebuggingEnabled {
    DSPNetworkObserver.enabled = networkDebuggingEnabled;
}

- (NSUInteger)networkResponseCacheByteLimit {
    return DSPNetworkRecorder.defaultRecorder.responseCacheByteLimit;
}

- (void)setNetworkResponseCacheByteLimit:(NSUInteger)networkResponseCacheByteLimit {
    DSPNetworkRecorder.defaultRecorder.responseCacheByteLimit = networkResponseCacheByteLimit;
}

- (NSMutableArray<NSString *> *)networkRequestHostDenylist {
    return DSPNetworkRecorder.defaultRecorder.hostDenylist;
}

- (void)setNetworkRequestHostDenylist:(NSMutableArray<NSString *> *)networkRequestHostDenylist {
    DSPNetworkRecorder.defaultRecorder.hostDenylist = networkRequestHostDenylist;
}

- (void)setCustomViewerForContentType:(NSString *)contentType
            viewControllerFutureBlock:(DSPCustomContentViewerFuture)viewControllerFutureBlock {
    NSParameterAssert(contentType.length);
    NSParameterAssert(viewControllerFutureBlock);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    self.customContentTypeViewers[contentType.lowercaseString] = viewControllerFutureBlock;
}

@end
