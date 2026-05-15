#import "NSMapTable+DSP_Subscripting.h"

@implementation NSMapTable (DSP_Subscripting)

- (id)objectForKeyedSubscript:(id)key {
    return [self objectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key {
    [self setObject:obj forKey:key];
}

@end
