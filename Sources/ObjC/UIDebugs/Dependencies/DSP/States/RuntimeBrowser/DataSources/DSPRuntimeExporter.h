#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A class for exporting all runtime metadata to an SQLite database.
//API_AVAILABLE(ios(10.0))
@interface DSPRuntimeExporter : NSObject

+ (void)createRuntimeDatabaseAtPath:(NSString *)path
                    progressHandler:(void(^)(NSString *status))progress
                         completion:(void(^)(NSString *_Nullable error))completion;

+ (void)createRuntimeDatabaseAtPath:(NSString *)path
                          forImages:(nullable NSArray<NSString *> *)images
                    progressHandler:(void(^)(NSString *status))progress
                         completion:(void(^)(NSString *_Nullable error))completion;


@end

NS_ASSUME_NONNULL_END
