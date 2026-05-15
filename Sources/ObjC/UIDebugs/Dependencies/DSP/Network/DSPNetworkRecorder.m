#import "DSPNetworkRecorder.h"
#import "DSPNetworkCurlLogger.h"
#import "DSPNetworkTransaction.h"
#import "DSPUtility.h"
#import "DSPResources.h"
#import "NSUserDefaults+DSP.h"
#import "OSCache.h"

#define Synchronized(queue, obj) ({ \
    __block id __synchronized_retval = nil; \
    dispatch_sync(queue, ^{ __synchronized_retval = obj; }); \
    __synchronized_retval; \
})
    

NSString *const kDSPNetworkRecorderNewTransactionNotification = @"kDSPNetworkRecorderNewTransactionNotification";
NSString *const kDSPNetworkRecorderTransactionUpdatedNotification = @"kDSPNetworkRecorderTransactionUpdatedNotification";
NSString *const kDSPNetworkRecorderUserInfoTransactionKey = @"transaction";
NSString *const kDSPNetworkRecorderTransactionsClearedNotification = @"kDSPNetworkRecorderTransactionsClearedNotification";

NSString *const kDSPNetworkRecorderResponseCacheLimitDefaultsKey = @"com.dsp.responseCacheLimit";

@interface DSPNetworkRecorder ()

@property (nonatomic) OSCache *restCache;
@property (atomic) NSMutableArray<DSPHTTPTransaction *> *orderedHTTPTransactions;
@property (atomic) NSMutableArray<DSPWebsocketTransaction *> *orderedWSTransactions;
@property (atomic) NSMutableArray<DSPFirebaseTransaction *> *orderedFirebaseTransactions;
@property (atomic) NSMutableDictionary<NSString *, __kindof DSPNetworkTransaction *> *requestIDsToTransactions;
@property (nonatomic) dispatch_queue_t queue;

@end

@implementation DSPNetworkRecorder

- (instancetype)init {
    self = [super init];
    if (self) {
        self.restCache = [OSCache new];
        NSUInteger responseCacheLimit = [[NSUserDefaults.standardUserDefaults
            objectForKey:kDSPNetworkRecorderResponseCacheLimitDefaultsKey] unsignedIntegerValue
        ];
        
        // Default to 25 MB max. The cache will purge earlier if there is memory pressure.
        self.restCache.totalCostLimit = responseCacheLimit ?: 25 * 1024 * 1024;
        [self.restCache setTotalCostLimit:responseCacheLimit];
        
        self.orderedWSTransactions = [NSMutableArray new];
        self.orderedHTTPTransactions = [NSMutableArray new];
        self.orderedFirebaseTransactions = [NSMutableArray new];
        self.requestIDsToTransactions = [NSMutableDictionary new];
        self.hostDenylist = NSUserDefaults.standardUserDefaults.dsp_networkHostDenylist.mutableCopy;

        // Serial queue used because we use mutable objects that are not thread safe
        self.queue = dispatch_queue_create("com.dsp.DSPNetworkRecorder", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

+ (instancetype)defaultRecorder {
    static DSPNetworkRecorder *defaultRecorder = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultRecorder = [self new];
    });
    
    return defaultRecorder;
}

#pragma mark - Public Data Access

- (NSUInteger)responseCacheByteLimit {
    return self.restCache.totalCostLimit;
}

- (void)setResponseCacheByteLimit:(NSUInteger)responseCacheByteLimit {
    self.restCache.totalCostLimit = responseCacheByteLimit;
    [NSUserDefaults.standardUserDefaults
        setObject:@(responseCacheByteLimit)
        forKey:kDSPNetworkRecorderResponseCacheLimitDefaultsKey
    ];
}

- (NSArray<DSPHTTPTransaction *> *)HTTPTransactions {
    return Synchronized(self.queue, self.orderedHTTPTransactions.copy);
}

- (NSArray<DSPWebsocketTransaction *> *)websocketTransactions {
    return Synchronized(self.queue, self.orderedWSTransactions.copy);
}

- (NSArray<DSPFirebaseTransaction *> *)firebaseTransactions {
    return Synchronized(self.queue, self.orderedFirebaseTransactions.copy);
}

- (NSData *)cachedResponseBodyForTransaction:(DSPHTTPTransaction *)transaction {
    return [self.restCache objectForKey:transaction.requestID];
}

- (void)clearRecordedActivity {
    dispatch_async(self.queue, ^{
        [self.restCache removeAllObjects];
        [self.orderedWSTransactions removeAllObjects];
        [self.orderedHTTPTransactions removeAllObjects];
        [self.orderedFirebaseTransactions removeAllObjects];
        [self.requestIDsToTransactions removeAllObjects];
        
        [self notify:kDSPNetworkRecorderTransactionsClearedNotification transaction:nil];
    });
}

- (void)clearRecordedActivity:(DSPNetworkTransactionKind)kind matching:(NSString *)query {
    dispatch_async(self.queue, ^{
        switch (kind) {
            case DSPNetworkTransactionKindFirebase: {
                [self.orderedFirebaseTransactions dsp_filter:^BOOL(DSPFirebaseTransaction *obj, NSUInteger idx) {
                    return ![obj matchesQuery:query];
                }];
                break;
            }
            case DSPNetworkTransactionKindREST: {
                NSArray<DSPHTTPTransaction *> *toRemove;
                toRemove = [self.orderedHTTPTransactions dsp_filtered:^BOOL(DSPHTTPTransaction *obj, NSUInteger idx) {
                    return [obj matchesQuery:query];
                }];
                
                // Remove from cache
                for (DSPHTTPTransaction *t in toRemove) {
                    [self.restCache removeObjectForKey:t.requestID];
                }
                
                // Remove from list
                [self.orderedHTTPTransactions removeObjectsInArray:toRemove];
                
                break;
            }
            case DSPNetworkTransactionKindWebsockets: {
                [self.orderedWSTransactions dsp_filter:^BOOL(DSPWebsocketTransaction *obj, NSUInteger idx) {
                    return ![obj matchesQuery:query];
                }];
                break;
            }
        }
        
        [self notify:kDSPNetworkRecorderTransactionsClearedNotification transaction:nil];
    });
}

- (void)clearExcludedTransactions {
    dispatch_sync(self.queue, ^{
        self.orderedHTTPTransactions = ({
            [self.orderedHTTPTransactions dsp_filtered:^BOOL(DSPHTTPTransaction *ta, NSUInteger idx) {
                NSString *host = ta.request.URL.host;
                for (NSString *excluded in self.hostDenylist) {
                    if ([host hasSuffix:excluded]) {
                        return NO;
                    }
                }
                
                return YES;
            }];
        });
    });
}

- (void)synchronizeDenylist {
    NSUserDefaults.standardUserDefaults.dsp_networkHostDenylist = self.hostDenylist;
}

#pragma mark - Network Events

- (void)recordRequestWillBeSentWithRequestID:(NSString *)requestID
                                     request:(NSURLRequest *)request
                            redirectResponse:(NSURLResponse *)redirectResponse {
    for (NSString *host in self.hostDenylist) {
        if ([request.URL.host hasSuffix:host]) {
            return;
        }
    }
    
    DSPHTTPTransaction *transaction = [DSPHTTPTransaction request:request identifier:requestID];

    // Before async block to keep times accurate
    if (redirectResponse) {
        [self recordResponseReceivedWithRequestID:requestID response:redirectResponse];
        [self recordLoadingFinishedWithRequestID:requestID responseBody:nil];
    }

    // A redirect is always a new request
    dispatch_async(self.queue, ^{
        [self.orderedHTTPTransactions insertObject:transaction atIndex:0];
        self.requestIDsToTransactions[requestID] = transaction;

        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordResponseReceivedWithRequestID:(NSString *)requestID response:(NSURLResponse *)response {
    // Before async block to stay accurate
    NSDate *responseDate = [NSDate date];

    dispatch_async(self.queue, ^{
        DSPHTTPTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.response = response;
        transaction.state = DSPNetworkTransactionStateReceivingData;
        transaction.latency = -[transaction.startTime timeIntervalSinceDate:responseDate];

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordDataReceivedWithRequestID:(NSString *)requestID dataLength:(int64_t)dataLength {
    dispatch_async(self.queue, ^{
        DSPHTTPTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.receivedDataLength += dataLength;
        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordLoadingFinishedWithRequestID:(NSString *)requestID responseBody:(NSData *)responseBody {
    NSDate *finishedDate = [NSDate date];

    dispatch_async(self.queue, ^{
        DSPHTTPTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.state = DSPNetworkTransactionStateFinished;
        transaction.duration = -[transaction.startTime timeIntervalSinceDate:finishedDate];

        BOOL shouldCache = responseBody.length > 0;
        if (!self.shouldCacheMediaResponses) {
            NSArray<NSString *> *ignoredMIMETypePrefixes = @[ @"audio", @"image", @"video" ];
            for (NSString *ignoredPrefix in ignoredMIMETypePrefixes) {
                shouldCache = shouldCache && ![transaction.response.MIMEType hasPrefix:ignoredPrefix];
            }
        }
        
        if (shouldCache) {
            [self.restCache setObject:responseBody forKey:requestID cost:responseBody.length];
        }

        NSString *mimeType = transaction.response.MIMEType;
        if ([mimeType hasPrefix:@"image/"] && responseBody.length > 0) {
            // Thumbnail image previews on a separate background queue
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSInteger maxPixelDimension = UIScreen.mainScreen.scale * 32.0;
                transaction.thumbnail = [DSPUtility
                    thumbnailedImageWithMaxPixelDimension:maxPixelDimension
                    fromImageData:responseBody
                ];
                [self postUpdateNotificationForTransaction:transaction];
            });
        } else if ([mimeType isEqual:@"application/json"]) {
            transaction.thumbnail = DSPResources.jsonIcon;
        } else if ([mimeType isEqual:@"text/plain"]){
            transaction.thumbnail = DSPResources.textPlainIcon;
        } else if ([mimeType isEqual:@"text/html"]) {
            transaction.thumbnail = DSPResources.htmlIcon;
        } else if ([mimeType isEqual:@"application/x-plist"]) {
            transaction.thumbnail = DSPResources.plistIcon;
        } else if ([mimeType isEqual:@"application/octet-stream"] || [mimeType isEqual:@"application/binary"]) {
            transaction.thumbnail = DSPResources.binaryIcon;
        } else if ([mimeType containsString:@"javascript"]) {
            transaction.thumbnail = DSPResources.jsIcon;
        } else if ([mimeType containsString:@"xml"]) {
            transaction.thumbnail = DSPResources.xmlIcon;
        } else if ([mimeType hasPrefix:@"audio"]) {
            transaction.thumbnail = DSPResources.audioIcon;
        } else if ([mimeType hasPrefix:@"video"]) {
            transaction.thumbnail = DSPResources.videoIcon;
        } else if ([mimeType hasPrefix:@"text"]) {
            transaction.thumbnail = DSPResources.textIcon;
        }
        
        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordLoadingFailedWithRequestID:(NSString *)requestID error:(NSError *)error {
    dispatch_async(self.queue, ^{
        DSPHTTPTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.state = DSPNetworkTransactionStateFailed;
        transaction.duration = -[transaction.startTime timeIntervalSinceNow];
        transaction.error = error;

        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordMechanism:(NSString *)mechanism forRequestID:(NSString *)requestID {
    dispatch_async(self.queue, ^{
        DSPHTTPTransaction *transaction = self.requestIDsToTransactions[requestID];
        if (!transaction) {
            return;
        }
        
        transaction.requestMechanism = mechanism;
        [self postUpdateNotificationForTransaction:transaction];
    });
}

#pragma mark - Websocket Events

- (void)recordWebsocketMessageSend:(NSURLSessionWebSocketMessage *)message task:(NSURLSessionWebSocketTask *)task {
    dispatch_async(self.queue, ^{
        DSPWebsocketTransaction *send = [DSPWebsocketTransaction
            withMessage:message task:task direction:DSPWebsocketOutgoing
        ];
        
        [self.orderedWSTransactions insertObject:send atIndex:0];
        [self postNewTransactionNotificationWithTransaction:send];
    });
}

- (void)recordWebsocketMessageSendCompletion:(NSURLSessionWebSocketMessage *)message error:(NSError *)error {
    dispatch_async(self.queue, ^{
        DSPWebsocketTransaction *send = [self.orderedWSTransactions dsp_firstWhere:^BOOL(DSPWebsocketTransaction *t) {
            return t.message == message;
        }];
        send.error = error;
        send.state = error ? DSPNetworkTransactionStateFailed : DSPNetworkTransactionStateFinished;
        
        [self postUpdateNotificationForTransaction:send];
    });
}

- (void)recordWebsocketMessageReceived:(NSURLSessionWebSocketMessage *)message task:(NSURLSessionWebSocketTask *)task {
    dispatch_async(self.queue, ^{
        DSPWebsocketTransaction *receive = [DSPWebsocketTransaction
            withMessage:message task:task direction:DSPWebsocketIncoming
        ];
        
        [self.orderedWSTransactions insertObject:receive atIndex:0];
        [self postNewTransactionNotificationWithTransaction:receive];
    });
}

#pragma mark - Firebase, Reading

- (void)recordFIRQueryWillFetch:(FIRQuery *)query withTransactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        DSPFirebaseTransaction *transaction = [DSPFirebaseTransaction queryFetch:query];
        self.requestIDsToTransactions[transactionID] = transaction;
        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordFIRDocumentWillFetch:(FIRDocumentReference *)document withTransactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        DSPFirebaseTransaction *transaction = [DSPFirebaseTransaction documentFetch:document];
        self.requestIDsToTransactions[transactionID] = transaction;
        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordFIRQueryDidFetch:(FIRQuerySnapshot *)response error:(NSError *)error transactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        DSPFirebaseTransaction *transaction = self.requestIDsToTransactions[transactionID];
        if (!transaction) {
            return;
        }
        
        transaction.error = error;
        transaction.documents = response.documents;
        transaction.state = DSPNetworkTransactionStateFinished;
        [self.orderedFirebaseTransactions insertObject:transaction atIndex:0];
        
        [self postUpdateNotificationForTransaction:transaction];
    });
}

- (void)recordFIRDocumentDidFetch:(FIRDocumentSnapshot *)response error:(NSError *)error transactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        DSPFirebaseTransaction *transaction = self.requestIDsToTransactions[transactionID];
        if (!transaction) {
            return;
        }
        
        transaction.error = error;
        transaction.documents = response ? @[response] : @[];
        transaction.state = DSPNetworkTransactionStateFinished;
        [self.orderedFirebaseTransactions insertObject:transaction atIndex:0];
        
        [self postUpdateNotificationForTransaction:transaction];
    });
}

#pragma mark Firebase, Writing

- (void)recordFIRWillSetData:(FIRDocumentReference *)doc
                        data:(NSDictionary *)documentData
                       merge:(NSNumber *)yesorno
                 mergeFields:(NSArray *)fields
               transactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        DSPFirebaseTransaction *transaction = [DSPFirebaseTransaction
            setData:doc data:documentData merge:yesorno mergeFields:fields
        ];
        self.requestIDsToTransactions[transactionID] = transaction;
        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordFIRWillUpdateData:(FIRDocumentReference *)doc fields:(NSDictionary *)fields
                  transactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        DSPFirebaseTransaction *transaction = [DSPFirebaseTransaction updateData:doc data:fields];
        self.requestIDsToTransactions[transactionID] = transaction;
        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordFIRWillDeleteDocument:(FIRDocumentReference *)doc transactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        DSPFirebaseTransaction *transaction = [DSPFirebaseTransaction deleteDocument:doc];
        self.requestIDsToTransactions[transactionID] = transaction;
        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordFIRWillAddDocument:(FIRCollectionReference *)initiator document:(FIRDocumentReference *)doc
                   transactionID:(NSString *)transactionID {
    dispatch_async(self.queue, ^{
        DSPFirebaseTransaction *transaction = [DSPFirebaseTransaction
            addDocument:initiator document:doc
        ];
        self.requestIDsToTransactions[transactionID] = transaction;
        [self postNewTransactionNotificationWithTransaction:transaction];
    });
}

- (void)recordFIRDidSetData:(NSError *)error transactionID:(NSString *)transactionID {
    [self firebaseTransaction:transactionID didUpdate:error];
}

- (void)recordFIRDidUpdateData:(NSError *)error transactionID:(NSString *)transactionID {
    [self firebaseTransaction:transactionID didUpdate:error];
}

- (void)recordFIRDidDeleteDocument:(NSError *)error transactionID:(NSString *)transactionID {
    [self firebaseTransaction:transactionID didUpdate:error];
}

- (void)recordFIRDidAddDocument:(NSError *)error transactionID:(NSString *)transactionID {
    [self firebaseTransaction:transactionID didUpdate:error];
}

- (void)firebaseTransaction:(NSString *)transactionID didUpdate:(NSError *)error {
    dispatch_async(self.queue, ^{
        DSPFirebaseTransaction *transaction = self.requestIDsToTransactions[transactionID];
        if (!transaction) {
            return;
        }
        
        transaction.error = error;
        transaction.state = DSPNetworkTransactionStateFinished;
        [self.orderedFirebaseTransactions insertObject:transaction atIndex:0];
        
        [self postUpdateNotificationForTransaction:transaction];
    });
}

#pragma mark - Notification Posting

- (void)postNewTransactionNotificationWithTransaction:(DSPNetworkTransaction *)transaction {
    [self notify:kDSPNetworkRecorderNewTransactionNotification transaction:transaction];
}

- (void)postUpdateNotificationForTransaction:(DSPNetworkTransaction *)transaction {
    [self notify:kDSPNetworkRecorderTransactionUpdatedNotification transaction:transaction];
}

- (void)notify:(NSString *)name transaction:(DSPNetworkTransaction *)transaction {
    NSDictionary *userInfo = nil;
    if (transaction) {
        userInfo = @{ kDSPNetworkRecorderUserInfoTransactionKey : transaction };
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSNotificationCenter.defaultCenter postNotificationName:name object:self userInfo:userInfo];
    });
}

@end
