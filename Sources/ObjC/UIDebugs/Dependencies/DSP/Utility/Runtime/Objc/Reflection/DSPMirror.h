#import <Foundation/Foundation.h>
#import <objc/runtime.h>
@class DSPMethod, DSPProperty, DSPIvar, DSPProtocol;

NS_ASSUME_NONNULL_BEGIN

#pragma mark DSPMirror Protocol
NS_SWIFT_NAME(DSPMirrorProtocol)
@protocol DSPMirror <NSObject>

/// Swift initializer
/// @throws If a metaclass object is passed in.
- (instancetype)initWithSubject:(id)objectOrClass NS_SWIFT_NAME(init(reflecting:));

/// The underlying object or \c Class used to create this \c DSPMirror.
@property (nonatomic, readonly) id   value;
/// Whether \c value was a class or a class instance.
@property (nonatomic, readonly) BOOL isClass;
/// The name of the \c Class of the \c value property.
@property (nonatomic, readonly) NSString *className;

@property (nonatomic, readonly) NSArray<DSPProperty *> *properties;
@property (nonatomic, readonly) NSArray<DSPProperty *> *classProperties;
@property (nonatomic, readonly) NSArray<DSPIvar *>     *ivars;
@property (nonatomic, readonly) NSArray<DSPMethod *>   *methods;
@property (nonatomic, readonly) NSArray<DSPMethod *>   *classMethods;
@property (nonatomic, readonly) NSArray<DSPProtocol *> *protocols;

/// Super mirrors are initialized with the class that corresponds to the value passed in.
/// If you passed in an instance of a class, it's superclass is used to create this mirror.
/// If you passed in a class, then that class's superclass is used.
///
/// @note This property should be computed, not cached.
@property (nonatomic, readonly, nullable) id<DSPMirror> superMirror NS_SWIFT_NAME(superMirror);

@end

#pragma mark DSPMirror Class
@interface DSPMirror : NSObject <DSPMirror>

/// Reflects an instance of an object or \c Class.
/// @discussion \c DSPMirror will immediately gather all useful information. Consider using the
/// \c NSObject categories provided if your code will only use a few pieces of information,
/// or if your code needs to run faster.
///
/// Regardless of whether you reflect an instance or a class object, \c methods and \c properties
/// will be populated with instance methods and properties, and \c classMethods and \c classProperties
/// will be populated with class methods and properties.
///
/// @param objectOrClass An instance of an objct or a \c Class object.
/// @throws If a metaclass object is passed in.
/// @return An instance of \c DSPMirror.
+ (instancetype)reflect:(id)objectOrClass;

@property (nonatomic, readonly) id   value;
@property (nonatomic, readonly) BOOL isClass;
@property (nonatomic, readonly) NSString *className;

@property (nonatomic, readonly) NSArray<DSPProperty *> *properties;
@property (nonatomic, readonly) NSArray<DSPProperty *> *classProperties;
@property (nonatomic, readonly) NSArray<DSPIvar *>     *ivars;
@property (nonatomic, readonly) NSArray<DSPMethod *>   *methods;
@property (nonatomic, readonly) NSArray<DSPMethod *>   *classMethods;
@property (nonatomic, readonly) NSArray<DSPProtocol *> *protocols;

@property (nonatomic, readonly, nullable) DSPMirror *superMirror NS_SWIFT_NAME(superMirror);

@end


@interface DSPMirror (ExtendedMirror)

/// @return The instance method with the given name, or \c nil if one does not exist.
- (nullable DSPMethod *)methodNamed:(nullable NSString *)name;
/// @return The class method with the given name, or \c nil if one does not exist.
- (nullable DSPMethod *)classMethodNamed:(nullable NSString *)name;
/// @return The instance property with the given name, or \c nil if one does not exist.
- (nullable DSPProperty *)propertyNamed:(nullable NSString *)name;
/// @return The class property with the given name, or \c nil if one does not exist.
- (nullable DSPProperty *)classPropertyNamed:(nullable NSString *)name;
/// @return The instance variable with the given name, or \c nil if one does not exist.
- (nullable DSPIvar *)ivarNamed:(nullable NSString *)name;
/// @return The protocol with the given name, or \c nil if one does not exist.
- (nullable DSPProtocol *)protocolNamed:(nullable NSString *)name;

@end

NS_ASSUME_NONNULL_END
