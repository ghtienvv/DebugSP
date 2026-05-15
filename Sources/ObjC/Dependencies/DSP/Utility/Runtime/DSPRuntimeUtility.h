#import "DSPRuntimeConstants.h"
@class DSPObjectRef;

#define PropertyKey(suffix) kDSPPropertyAttributeKey##suffix : @""
#define PropertyKeyGetter(getter) kDSPPropertyAttributeKeyCustomGetter : NSStringFromSelector(@selector(getter))
#define PropertyKeySetter(setter) kDSPPropertyAttributeKeyCustomSetter : NSStringFromSelector(@selector(setter))

/// Takes: min iOS version, property name, target class, property type, and a list of attributes
#define DSPRuntimeUtilityTryAddProperty(iOS_atLeast, name, cls, type, ...) ({ \
    if (@available(iOS iOS_atLeast, *)) { \
        NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithDictionary:@{ \
            kDSPPropertyAttributeKeyTypeEncoding : @(type), \
            __VA_ARGS__ \
        }]; \
        [DSPRuntimeUtility \
            tryAddPropertyWithName:#name \
            attributes:attrs \
            toClass:cls \
        ]; \
    } \
})

/// Takes: min iOS version, property name, target class, property type, and a list of attributes
#define DSPRuntimeUtilityTryAddNonatomicProperty(iOS_atLeast, name, cls, type, ...) \
    DSPRuntimeUtilityTryAddProperty(iOS_atLeast, name, cls, @encode(type), PropertyKey(NonAtomic), __VA_ARGS__);
/// Takes: min iOS version, property name, target class, property type (class name), and a list of attributes
#define DSPRuntimeUtilityTryAddObjectProperty(iOS_atLeast, name, cls, type, ...) \
    DSPRuntimeUtilityTryAddProperty(iOS_atLeast, name, cls, DSPEncodeClass(type), PropertyKey(NonAtomic), __VA_ARGS__);

extern NSString * const DSPRuntimeUtilityErrorDomain;

typedef NS_ENUM(NSInteger, DSPRuntimeUtilityErrorCode) {
    // Start at a random value instead of 0 to avoid confusion with an absent code
    DSPRuntimeUtilityErrorCodeDoesNotRecognizeSelector = 0xbabe,
    DSPRuntimeUtilityErrorCodeInvocationFailed,
    DSPRuntimeUtilityErrorCodeArgumentTypeMismatch
};

@interface DSPRuntimeUtility : NSObject

#pragma mark - General Helpers

/// Calls into \c DSPPointerIsValidObjcObject()
+ (BOOL)pointerIsValidObjcObject:(const void *)pointer;
/// Unwraps raw pointers to objects stored in NSValue, and re-boxes C strings into NSStrings.
+ (id)potentiallyUnwrapBoxedPointer:(id)returnedObjectOrNil type:(const DSPTypeEncoding *)returnType;
/// Some fields have a name in their encoded string (e.g. \"width\"d)
/// @return the offset to skip the field name, 0 if there is no name
+ (NSUInteger)fieldNameOffsetForTypeEncoding:(const DSPTypeEncoding *)typeEncoding;
/// Given name "foo" and type "int" this would return "int foo", but
/// given name "foo" and type "T *" it would return "T *foo"
+ (NSString *)appendName:(NSString *)name toType:(NSString *)typeEncoding;

/// @return The class hierarchy for the given object or class,
/// from the current class to the root-most class.
+ (NSArray<Class> *)classHierarchyOfObject:(id)objectOrClass;
/// @return Every subclass of the given class name.
+ (NSArray<DSPObjectRef *> *)subclassesOfClassWithName:(NSString *)className;

/// Used to describe an object in brief within an explorer row
+ (NSString *)summaryForObject:(id)value;
+ (NSString *)safeClassNameForObject:(id)object;
+ (NSString *)safeDescriptionForObject:(id)object;
+ (NSString *)safeDebugDescriptionForObject:(id)object;

+ (BOOL)safeObject:(id)object isKindOfClass:(Class)cls;
+ (BOOL)safeObject:(id)object respondsToSelector:(SEL)sel;

#pragma mark - Property Helpers

+ (BOOL)tryAddPropertyWithName:(const char *)name
                    attributes:(NSDictionary<NSString *, NSString *> *)attributePairs
                       toClass:(__unsafe_unretained Class)theClass;
+ (NSArray<NSString *> *)allPropertyAttributeKeys;

#pragma mark - Method Helpers

+ (NSArray *)prettyArgumentComponentsForMethod:(Method)method;

#pragma mark - Method Calling/Field Editing

+ (id)performSelector:(SEL)selector onObject:(id)object;
+ (id)performSelector:(SEL)selector
             onObject:(id)object
        withArguments:(NSArray *)arguments
                error:(NSError * __autoreleasing *)error;
+ (id)performSelector:(SEL)selector
             onObject:(id)object
        withArguments:(NSArray *)arguments
      allowForwarding:(BOOL)mightForwardMsgSend
                error:(NSError * __autoreleasing *)error;

+ (NSString *)editableJSONStringForObject:(id)object;
+ (id)objectValueFromEditableJSONString:(NSString *)string;
+ (NSValue *)valueForNumberWithObjCType:(const char *)typeEncoding fromInputString:(NSString *)inputString;
+ (void)enumerateTypesInStructEncoding:(const char *)structEncoding
                            usingBlock:(void (^)(NSString *structName,
                                                 const char *fieldTypeEncoding,
                                                 NSString *prettyTypeEncoding,
                                                 NSUInteger fieldIndex,
                                                 NSUInteger fieldOffset))typeBlock;
+ (NSValue *)valueForPrimitivePointer:(void *)pointer objCType:(const char *)type;

#pragma mark - Metadata Helpers

+ (NSString *)readableTypeForEncoding:(NSString *)encodingString;

@end
