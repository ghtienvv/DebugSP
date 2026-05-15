#import "DSPLogController.h"

@interface DSPASLLogController : NSObject <DSPLogController>

/// Guaranteed to call back on the main thread.
+ (instancetype)withUpdateHandler:(void(^)(NSArray<DSPSystemLogMessage *> *newMessages))newMessagesHandler;

- (BOOL)startMonitoring;

@end
