#import "DSPLogController.h"

#define DSPOSLogAvailable() (NSProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 10)

/// The log controller used for iOS 10 and up.
@interface DSPOSLogController : NSObject <DSPLogController>

+ (instancetype)withUpdateHandler:(void(^)(NSArray<DSPSystemLogMessage *> *newMessages))newMessagesHandler;

- (BOOL)startMonitoring;

/// Whether log messages are to be recorded and kept in-memory in the background.
/// You do not need to initialize this value, only change it.
@property (nonatomic) BOOL persistent;
/// Used mostly internally, but also used by the log VC to persist messages
/// that were created prior to enabling persistence.
@property (nonatomic) NSMutableArray<DSPSystemLogMessage *> *messages;

@end
