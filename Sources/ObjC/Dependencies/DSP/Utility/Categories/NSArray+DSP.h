#import <Foundation/Foundation.h>

@interface NSArray<T> (Functional)

/// Actually more like flatmap, but it seems like the objc way to allow returning nil to omit objects.
/// So, return nil from the block to omit objects, and return an object to include it in the new array.
/// Unlike flatmap, however, this will not flatten arrays of arrays into a single array.
- (__kindof NSArray *)dsp_mapped:(id(^)(T obj, NSUInteger idx))mapFunc;
/// Like dsp_mapped, but expects arrays to be returned, and flattens them into one array.
- (__kindof NSArray *)dsp_flatmapped:(NSArray *(^)(id, NSUInteger idx))block;
- (instancetype)dsp_filtered:(BOOL(^)(T obj, NSUInteger idx))filterFunc;
- (void)dsp_forEach:(void(^)(T obj, NSUInteger idx))block;

/// Unlike \c subArrayWithRange: this will not throw an exception if \c maxLength
/// is greater than the size of the array. If the array has one element and
/// \c maxLength is greater than 1, you get an array with 1 element back.
- (instancetype)dsp_subArrayUpto:(NSUInteger)maxLength;

+ (instancetype)dsp_forEachUpTo:(NSUInteger)bound map:(T(^)(NSUInteger i))block;
+ (instancetype)dsp_mapped:(id<NSFastEnumeration>)collection block:(id(^)(T obj, NSUInteger idx))mapFunc;

- (instancetype)dsp_sortedUsingSelector:(SEL)selector;

- (T)dsp_firstWhere:(BOOL(^)(T obj))meetingCriteria;

@end

@interface NSMutableArray<T> (Functional)

- (void)dsp_filter:(BOOL(^)(T obj, NSUInteger idx))filterFunc;

@end
