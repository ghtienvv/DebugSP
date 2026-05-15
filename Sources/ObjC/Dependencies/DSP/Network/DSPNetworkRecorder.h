#import <Foundation/Foundation.h>

// Notifications posted when the record is updated
extern NSString *const kDSPNetworkRecorderNewTransactionNotification;
extern NSString *const kDSPNetworkRecorderTransactionUpdatedNotification;
extern NSString *const kDSPNetworkRecorderUserInfoTransactionKey;
extern NSString *const kDSPNetworkRecorderTransactionsClearedNotification;

@class DSPNetworkTransaction, DSPHTTPTransaction, DSPWebsocketTransaction, DSPFirebaseTransaction;
@class FIRQuery, FIRDocumentReference, FIRCollectionReference, FIRDocumentSnapshot, FIRQuerySnapshot;

typedef NS_ENUM(NSUInteger, DSPNetworkTransactionKind) {
    DSPNetworkTransactionKindFirebase = 0,
    DSPNetworkTransactionKindREST,
    DSPNetworkTransactionKindWebsockets,
};

@interface DSPNetworkRecorder : NSObject

/// In general, it only makes sense to have one recorder for the entire application.
@property (nonatomic, readonly, class) DSPNetworkRecorder *defaultRecorder;

/// Defaults to 25 MB if never set. Values set here are persisted across launches of the app.
@property (nonatomic) NSUInteger responseCacheByteLimit;

/// If NO, the recorder not cache will not cache response for content types
/// with an "image", "video", or "audio" prefix.
@property (nonatomic) BOOL shouldCacheMediaResponses;

@property (nonatomic) NSMutableArray<NSString *> *hostDenylist;

/// Call this after adding to or setting the \c hostDenylist to remove excluded transactions
- (void)clearExcludedTransactions;

/// Call this to save the denylist to the disk to be loaded next time
- (void)synchronizeDenylist;


#pragma mark Accessing recorded network activity

/// Array of DSPHTTPTransaction objects ordered by start time with the newest first.
@property (nonatomic, readonly) NSArray<DSPHTTPTransaction *> *HTTPTransactions;
/// Array of DSPWebsocketTransaction objects ordered by start time with the newest first.
@property (nonatomic, readonly) NSArray<DSPWebsocketTransaction *> *websocketTransactions API_AVAILABLE(ios(13.0));
/// Array of DSPFirebaseTransaction objects ordered by start time with the newest first.
@property (nonatomic, readonly) NSArray<DSPFirebaseTransaction *> *firebaseTransactions;

/// The full response data IFF it hasn't been purged due to memory pressure.
- (NSData *)cachedResponseBodyForTransaction:(DSPHTTPTransaction *)transaction;

/// Dumps all network transactions and cached response bodies.
- (void)clearRecordedActivity;

/// Clear only transactions matching the given query.
- (void)clearRecordedActivity:(DSPNetworkTransactionKind)kind matching:(NSString *)query;


#pragma mark Recording network activity

/// Call when app is about to send HTTP request.
- (void)recordRequestWillBeSentWithRequestID:(NSString *)requestID
                                     request:(NSURLRequest *)request
                            redirectResponse:(NSURLResponse *)redirectResponse;

/// Call when HTTP response is available.
- (void)recordResponseReceivedWithRequestID:(NSString *)requestID response:(NSURLResponse *)response;

/// Call when data chunk is received over the network.
- (void)recordDataReceivedWithRequestID:(NSString *)requestID dataLength:(int64_t)dataLength;

/// Call when HTTP request has finished loading.
- (void)recordLoadingFinishedWithRequestID:(NSString *)requestID responseBody:(NSData *)responseBody;

/// Call when HTTP request has failed to load.
- (void)recordLoadingFailedWithRequestID:(NSString *)requestID error:(NSError *)error;

/// Call to set the request mechanism anytime after recordRequestWillBeSent... has been called.
/// This string can be set to anything useful about the API used to make the request.
- (void)recordMechanism:(NSString *)mechanism forRequestID:(NSString *)requestID;

- (void)recordWebsocketMessageSend:(NSURLSessionWebSocketMessage *)message
                              task:(NSURLSessionWebSocketTask *)task API_AVAILABLE(ios(13.0));
- (void)recordWebsocketMessageSendCompletion:(NSURLSessionWebSocketMessage *)message
                                       error:(NSError *)error API_AVAILABLE(ios(13.0));

- (void)recordWebsocketMessageReceived:(NSURLSessionWebSocketMessage *)message
                                  task:(NSURLSessionWebSocketTask *)task API_AVAILABLE(ios(13.0));

- (void)recordFIRQueryWillFetch:(FIRQuery *)query withTransactionID:(NSString *)transactionID;
- (void)recordFIRDocumentWillFetch:(FIRDocumentReference *)document withTransactionID:(NSString *)transactionID;

- (void)recordFIRQueryDidFetch:(FIRQuerySnapshot *)response error:(NSError *)error
                 transactionID:(NSString *)transactionID;
- (void)recordFIRDocumentDidFetch:(FIRDocumentSnapshot *)response error:(NSError *)error
                    transactionID:(NSString *)transactionID;

- (void)recordFIRWillSetData:(FIRDocumentReference *)doc
                        data:(NSDictionary *)documentData
                       merge:(NSNumber *)yesorno
                 mergeFields:(NSArray *)fields
               transactionID:(NSString *)transactionID;
- (void)recordFIRWillUpdateData:(FIRDocumentReference *)doc fields:(NSDictionary *)fields
                  transactionID:(NSString *)transactionID;
- (void)recordFIRWillDeleteDocument:(FIRDocumentReference *)doc transactionID:(NSString *)transactionID;
- (void)recordFIRWillAddDocument:(FIRCollectionReference *)initiator
                            document:(FIRDocumentReference *)doc
                   transactionID:(NSString *)transactionID;

- (void)recordFIRDidSetData:(NSError *)error transactionID:(NSString *)transactionID;
- (void)recordFIRDidUpdateData:(NSError *)error transactionID:(NSString *)transactionID;
- (void)recordFIRDidDeleteDocument:(NSError *)error transactionID:(NSString *)transactionID;
- (void)recordFIRDidAddDocument:(NSError *)error transactionID:(NSString *)transactionID;

@end
