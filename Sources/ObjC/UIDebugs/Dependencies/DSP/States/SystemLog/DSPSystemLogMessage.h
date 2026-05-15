#import <Foundation/Foundation.h>
#import <asl.h>
#import "ActivityStreamAPI.h"

NS_ASSUME_NONNULL_BEGIN

@interface DSPSystemLogMessage : NSObject

+ (instancetype)logMessageFromASLMessage:(aslmsg)aslMessage;
+ (instancetype)logMessageFromDate:(NSDate *)date text:(NSString *)text;

// ASL specific properties
@property (nonatomic, readonly, nullable) NSString *sender;
@property (nonatomic, readonly, nullable) aslmsg aslMessage;

@property (nonatomic, readonly) NSDate *date;
@property (nonatomic, readonly) NSString *messageText;
@property (nonatomic, readonly) long long messageID;

@end

NS_ASSUME_NONNULL_END
