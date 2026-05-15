#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface NSDictionary (ObjcRuntime)

/// \c kDSPPropertyAttributeKeyTypeEncoding is the only required key.
/// Keys representing a boolean value should have a value of \c YES instead of an empty string.
- (NSString *)propertyAttributesString;

+ (instancetype)attributesDictionaryForProperty:(objc_property_t)property;

@end
