#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OSCache <KeyType, ObjectType> : NSCache <NSFastEnumeration>

@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly) NSUInteger totalCost;

- (id)objectForKeyedSubscript:(KeyType <NSCopying>)key;
- (void)setObject:(ObjectType)obj forKeyedSubscript:(KeyType <NSCopying>)key;
- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(KeyType key, ObjectType obj, BOOL *stop))block;

@end


@protocol OSCacheDelegate <NSCacheDelegate>
@optional

- (BOOL)cache:(OSCache *)cache shouldEvictObject:(id)entry;
- (void)cache:(OSCache *)cache willEvictObject:(id)entry;

@end

NS_ASSUME_NONNULL_END
