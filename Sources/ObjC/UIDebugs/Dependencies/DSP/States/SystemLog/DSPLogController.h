#import <Foundation/Foundation.h>
#import "DSPSystemLogMessage.h"

@protocol DSPLogController <NSObject>

/// Guaranteed to call back on the main thread.
+ (instancetype)withUpdateHandler:(void(^)(NSArray<DSPSystemLogMessage *> *newMessages))newMessagesHandler;

- (BOOL)startMonitoring;

@end
