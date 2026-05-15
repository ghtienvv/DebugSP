#import "NSString+ObjcRuntime.h"
#import "DSPRuntimeUtility.h"

@implementation NSString (Utilities)

- (NSString *)stringbyDeletingCharacterAtIndex:(NSUInteger)idx {
    NSMutableString *string = self.mutableCopy;
    [string replaceCharactersInRange:NSMakeRange(idx, 1) withString:@""];
    return string;
}

/// See this link on how to construct a proper attributes string:
/// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
- (NSDictionary *)propertyAttributes {
    if (!self.length) return nil;
    
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    
    NSArray *components = [self componentsSeparatedByString:@","];
    for (NSString *attribute in components) {
        DSPPropertyAttribute c = (DSPPropertyAttribute)[attribute characterAtIndex:0];
        switch (c) {
            case DSPPropertyAttributeTypeEncoding:
                // Note: the type encoding here is not always correct. Radar: FB7499230
                attributes[kDSPPropertyAttributeKeyTypeEncoding] = [attribute stringbyDeletingCharacterAtIndex:0];
                break;
            case DSPPropertyAttributeBackingIvarName:
                attributes[kDSPPropertyAttributeKeyBackingIvarName] = [attribute stringbyDeletingCharacterAtIndex:0];
                break;
            case DSPPropertyAttributeCopy:
                attributes[kDSPPropertyAttributeKeyCopy] = @YES;
                break;
            case DSPPropertyAttributeCustomGetter:
                attributes[kDSPPropertyAttributeKeyCustomGetter] = [attribute stringbyDeletingCharacterAtIndex:0];
                break;
            case DSPPropertyAttributeCustomSetter:
                attributes[kDSPPropertyAttributeKeyCustomSetter] = [attribute stringbyDeletingCharacterAtIndex:0];
                break;
            case DSPPropertyAttributeDynamic:
                attributes[kDSPPropertyAttributeKeyDynamic] = @YES;
                break;
            case DSPPropertyAttributeGarbageCollectible:
                attributes[kDSPPropertyAttributeKeyGarbageCollectable] = @YES;
                break;
            case DSPPropertyAttributeNonAtomic:
                attributes[kDSPPropertyAttributeKeyNonAtomic] = @YES;
                break;
            case DSPPropertyAttributeOldTypeEncoding:
                attributes[kDSPPropertyAttributeKeyOldStyleTypeEncoding] = [attribute stringbyDeletingCharacterAtIndex:0];
                break;
            case DSPPropertyAttributeReadOnly:
                attributes[kDSPPropertyAttributeKeyReadOnly] = @YES;
                break;
            case DSPPropertyAttributeRetain:
                attributes[kDSPPropertyAttributeKeyRetain] = @YES;
                break;
            case DSPPropertyAttributeWeak:
                attributes[kDSPPropertyAttributeKeyWeak] = @YES;
                break;
        }
    }

    return attributes;
}

@end
