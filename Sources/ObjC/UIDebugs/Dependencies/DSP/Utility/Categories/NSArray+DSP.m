#import "NSArray+DSP.h"

#define DSPArrayClassIsMutable(me) ([[self class] isSubclassOfClass:[NSMutableArray class]])

@implementation NSArray (Functional)

- (__kindof NSArray *)dsp_mapped:(id (^)(id, NSUInteger))mapFunc {
    NSMutableArray *map = [NSMutableArray new];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id ret = mapFunc(obj, idx);
        if (ret) {
            [map addObject:ret];
        }
    }];

    if (self.count < 2048 && !DSPArrayClassIsMutable(self)) {
        return map.copy;
    }

    return map;
}

- (__kindof NSArray *)dsp_flatmapped:(NSArray *(^)(id, NSUInteger))block {
    NSMutableArray *array = [NSMutableArray new];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSArray *toAdd = block(obj, idx);
        if (toAdd) {
            [array addObjectsFromArray:toAdd];
        }
    }];

    if (array.count < 2048 && !DSPArrayClassIsMutable(self)) {
        return array.copy;
    }

    return array;
}

- (NSArray *)dsp_filtered:(BOOL (^)(id, NSUInteger))filterFunc {
    return [self dsp_mapped:^id(id obj, NSUInteger idx) {
        return filterFunc(obj, idx) ? obj : nil;
    }];
}

- (void)dsp_forEach:(void(^)(id, NSUInteger))block {
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        block(obj, idx);
    }];
}

- (instancetype)dsp_subArrayUpto:(NSUInteger)maxLength {
    if (maxLength > self.count) {
        if (DSPArrayClassIsMutable(self)) {
            return self.mutableCopy;
        }
        
        return self;
    }
    
    return [self subarrayWithRange:NSMakeRange(0, maxLength)];
}

+ (__kindof NSArray *)dsp_forEachUpTo:(NSUInteger)bound map:(id(^)(NSUInteger))block {
    NSMutableArray *array = [NSMutableArray new];
    for (NSUInteger i = 0; i < bound; i++) {
        id obj = block(i);
        if (obj) {
            [array addObject:obj];
        }
    }

    // For performance reasons, don't copy large arrays
    if (bound < 2048 && !DSPArrayClassIsMutable(self)) {
        return array.copy;
    }

    return array;
}

+ (instancetype)dsp_mapped:(id<NSFastEnumeration>)collection block:(id(^)(id obj, NSUInteger idx))mapFunc {
    NSMutableArray *array = [NSMutableArray new];
    NSInteger idx = 0;
    for (id obj in collection) {
        id ret = mapFunc(obj, idx++);
        if (ret) {
            [array addObject:ret];
        }
    }

    // For performance reasons, don't copy large arrays
    if (array.count < 2048) {
        return array.copy;
    }

    return array;
}

- (instancetype)dsp_sortedUsingSelector:(SEL)selector {
    if (DSPArrayClassIsMutable(self)) {
        NSMutableArray *me = (id)self;
        [me sortUsingSelector:selector];
        return me;
    } else {
        return [self sortedArrayUsingSelector:selector];
    }
}

- (id)dsp_firstWhere:(BOOL (^)(id))meetsCriteria {
    for (id e in self) {
        if (meetsCriteria(e)) {
            return e;
        }
    }
    
    return nil;
}

@end


@implementation NSMutableArray (Functional)

- (void)dsp_filter:(BOOL (^)(id, NSUInteger))keepObject {
    NSMutableIndexSet *toRemove = [NSMutableIndexSet new];
    
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (!keepObject(obj, idx)) {
            [toRemove addIndex:idx];
        }
    }];
    
    [self removeObjectsAtIndexes:toRemove];
}

@end
