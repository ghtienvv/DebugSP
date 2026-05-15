#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMapTable<KeyType, ObjectType> (DSP_Subscripting)

- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;
- (void)setObject:(nullable ObjectType)obj forKeyedSubscript:(KeyType <NSCopying>)key;

@end

NS_ASSUME_NONNULL_END
