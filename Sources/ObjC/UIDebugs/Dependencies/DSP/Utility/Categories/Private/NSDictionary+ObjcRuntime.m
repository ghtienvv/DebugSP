#import "NSDictionary+ObjcRuntime.h"
#import "DSPRuntimeUtility.h"

@implementation NSDictionary (ObjcRuntime)

/// See this link on how to construct a proper attributes string:
/// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
- (NSString *)propertyAttributesString {
    if (!self[kDSPPropertyAttributeKeyTypeEncoding]) return nil;
    
    NSMutableString *attributes = [NSMutableString new];
    [attributes appendFormat:@"T%@,", self[kDSPPropertyAttributeKeyTypeEncoding]];
    
    for (NSString *attribute in self.allKeys) {
        DSPPropertyAttribute c = (DSPPropertyAttribute)[attribute characterAtIndex:0];
        switch (c) {
            case DSPPropertyAttributeTypeEncoding:
                break;
            case DSPPropertyAttributeBackingIvarName:
                [attributes appendFormat:@"%@%@,",
                    kDSPPropertyAttributeKeyBackingIvarName,
                    self[kDSPPropertyAttributeKeyBackingIvarName]
                ];
                break;
            case DSPPropertyAttributeCopy:
                if ([self[kDSPPropertyAttributeKeyCopy] boolValue])
                [attributes appendFormat:@"%@,", kDSPPropertyAttributeKeyCopy];
                break;
            case DSPPropertyAttributeCustomGetter:
                [attributes appendFormat:@"%@%@,",
                    kDSPPropertyAttributeKeyCustomGetter,
                    self[kDSPPropertyAttributeKeyCustomGetter]
                ];
                break;
            case DSPPropertyAttributeCustomSetter:
                [attributes appendFormat:@"%@%@,",
                    kDSPPropertyAttributeKeyCustomSetter,
                    self[kDSPPropertyAttributeKeyCustomSetter]
                ];
                break;
            case DSPPropertyAttributeDynamic:
                if ([self[kDSPPropertyAttributeKeyDynamic] boolValue])
                [attributes appendFormat:@"%@,", kDSPPropertyAttributeKeyDynamic];
                break;
            case DSPPropertyAttributeGarbageCollectible:
                [attributes appendFormat:@"%@,", kDSPPropertyAttributeKeyGarbageCollectable];
                break;
            case DSPPropertyAttributeNonAtomic:
                if ([self[kDSPPropertyAttributeKeyNonAtomic] boolValue])
                [attributes appendFormat:@"%@,", kDSPPropertyAttributeKeyNonAtomic];
                break;
            case DSPPropertyAttributeOldTypeEncoding:
                [attributes appendFormat:@"%@%@,",
                    kDSPPropertyAttributeKeyOldStyleTypeEncoding,
                    self[kDSPPropertyAttributeKeyOldStyleTypeEncoding]
                ];
                break;
            case DSPPropertyAttributeReadOnly:
                if ([self[kDSPPropertyAttributeKeyReadOnly] boolValue])
                [attributes appendFormat:@"%@,", kDSPPropertyAttributeKeyReadOnly];
                break;
            case DSPPropertyAttributeRetain:
                if ([self[kDSPPropertyAttributeKeyRetain] boolValue])
                [attributes appendFormat:@"%@,", kDSPPropertyAttributeKeyRetain];
                break;
            case DSPPropertyAttributeWeak:
                if ([self[kDSPPropertyAttributeKeyWeak] boolValue])
                [attributes appendFormat:@"%@,", kDSPPropertyAttributeKeyWeak];
                break;
            default:
                return nil;
                break;
        }
    }
    
    [attributes deleteCharactersInRange:NSMakeRange(attributes.length-1, 1)];
    return attributes.copy;
}

+ (instancetype)attributesDictionaryForProperty:(objc_property_t)property {
    NSMutableDictionary *attrs = [NSMutableDictionary new];

    for (NSString *key in DSPRuntimeUtility.allPropertyAttributeKeys) {
        char *value = property_copyAttributeValue(property, key.UTF8String);
        if (value) {
            attrs[key] = [[NSString alloc]
                initWithBytesNoCopy:value
                length:strlen(value)
                encoding:NSUTF8StringEncoding
                freeWhenDone:YES
            ];
        }
    }

    return attrs.copy;
}

@end
