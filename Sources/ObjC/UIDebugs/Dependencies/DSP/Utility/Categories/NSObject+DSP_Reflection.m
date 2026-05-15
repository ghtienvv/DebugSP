#import "NSObject+DSP_Reflection.h"
#import "DSPClassBuilder.h"
#import "DSPMirror.h"
#import "DSPProperty.h"
#import "DSPMethod.h"
#import "DSPIvar.h"
#import "DSPProtocol.h"
#import "DSPPropertyAttributes.h"
#import "NSArray+DSP.h"
#import "DSPUtility.h"


NSString * DSPTypeEncodingString(const char *returnType, NSUInteger count, ...) {
    if (!returnType) return nil;
    
    NSMutableString *encoding = [NSMutableString new];
    [encoding appendFormat:@"%s%s%s", returnType, @encode(id), @encode(SEL)];
    
    va_list args;
    va_start(args, count);
    char *type = va_arg(args, char *);
    for (NSUInteger i = 0; i < count; i++, type = va_arg(args, char *)) {
        [encoding appendFormat:@"%s", type];
    }
    va_end(args);
    
    return encoding.copy;
}

NSArray<Class> *DSPGetAllSubclasses(Class cls, BOOL includeSelf) {
    if (!cls) return nil;
    
    Class *buffer = NULL;
    
    int count, size;
    do {
        count  = objc_getClassList(NULL, 0);
        buffer = (Class *)realloc(buffer, count * sizeof(*buffer));
        size   = objc_getClassList(buffer, count);
    } while (size != count);
    
    NSMutableArray *classes = [NSMutableArray new];
    if (includeSelf) {
        [classes addObject:cls];
    }
    
    for (int i = 0; i < count; i++) {
        Class candidate = buffer[i];
        Class superclass = candidate;
        while ((superclass = class_getSuperclass(superclass))) {
            if (superclass == cls) {
                [classes addObject:candidate];
                break;
            }
        }
    }
    
    free(buffer);
    return classes.copy;
}

NSArray<Class> *DSPGetClassHierarchy(Class cls, BOOL includeSelf) {
    if (!cls) return nil;
    
    NSMutableArray *classes = [NSMutableArray new];
    if (includeSelf) {
        [classes addObject:cls];
    }
    
    while ((cls = [cls superclass])) {
        [classes addObject:cls];
    };

    return classes.copy;
}

NSArray<DSPProtocol *> *DSPGetConformedProtocols(Class cls) {
    if (!cls) return nil;
    
    unsigned int count = 0;
    Protocol *__unsafe_unretained *list = class_copyProtocolList(cls, &count);
    NSArray<Protocol *> *protocols = [NSArray arrayWithObjects:list count:count];
    free(list);
    
    return [protocols dsp_mapped:^id(Protocol *pro, NSUInteger idx) {
        return [DSPProtocol protocol:pro];
    }];
}

NSArray<DSPIvar *> *DSPGetAllIvars(_Nullable Class cls) {
    if (!cls) return nil;
    
    unsigned int ivcount;
    Ivar *objcivars = class_copyIvarList(cls, &ivcount);
    NSArray *ivars = [NSArray dsp_forEachUpTo:ivcount map:^id(NSUInteger i) {
        return [DSPIvar ivar:objcivars[i]];
    }];

    free(objcivars);
    return ivars;
}

NSArray<DSPProperty *> *DSPGetAllProperties(_Nullable Class cls) {
    if (!cls) return nil;
    
    unsigned int pcount;
    objc_property_t *objcproperties = class_copyPropertyList(cls, &pcount);
    NSArray *properties = [NSArray dsp_forEachUpTo:pcount map:^id(NSUInteger i) {
        return [DSPProperty property:objcproperties[i] onClass:cls];
    }];

    free(objcproperties);
    return properties;
}

NSArray<DSPMethod *> *DSPGetAllMethods(_Nullable Class cls, BOOL instance) {
    if (!cls) return nil;

    unsigned int mcount;
    Method *objcmethods = class_copyMethodList(cls, &mcount);
    NSArray *methods = [NSArray dsp_forEachUpTo:mcount map:^id(NSUInteger i) {
        return [DSPMethod method:objcmethods[i] isInstanceMethod:instance];
    }];
    
    free(objcmethods);
    return methods;
}


#pragma mark NSProxy

@interface NSProxy (AnyObjectAdditions) @end
@implementation NSProxy (AnyObjectAdditions)

+ (void)load { DSP_EXIT_IF_NO_CTORS()
    // We need to get all of the methods in this file and add them to NSProxy. 
    // To do this we we need the class itself and it's metaclass.
    // Edit: also add them to Swift._SwiftObject
    Class NSProxyClass = [NSProxy class];
    Class NSProxy_meta = object_getClass(NSProxyClass);
    Class SwiftObjectClass = (
        NSClassFromString(@"SwiftObject") ?: NSClassFromString(@"Swift._SwiftObject")
    );
    
    // Copy all of the "dsp_" methods from NSObject
    id filterFunc = ^BOOL(DSPMethod *method, NSUInteger idx) {
        return [method.name hasPrefix:@"dsp_"];
    };
    NSArray *instanceMethods = [NSObject.dsp_allInstanceMethods dsp_filtered:filterFunc];
    NSArray *classMethods = [NSObject.dsp_allClassMethods dsp_filtered:filterFunc];
    
    DSPClassBuilder *proxy     = [DSPClassBuilder builderForClass:NSProxyClass];
    DSPClassBuilder *proxyMeta = [DSPClassBuilder builderForClass:NSProxy_meta];
    [proxy addMethods:instanceMethods];
    [proxyMeta addMethods:classMethods];
    
    if (SwiftObjectClass) {
        Class SwiftObject_meta = object_getClass(SwiftObjectClass);
        DSPClassBuilder *swiftObject = [DSPClassBuilder builderForClass:SwiftObjectClass];
        DSPClassBuilder *swiftObjectMeta = [DSPClassBuilder builderForClass:SwiftObject_meta];
        [swiftObject addMethods:instanceMethods];
        [swiftObjectMeta addMethods:classMethods];
        
        // So we can put Swift objects into dictionaries...
        [swiftObjectMeta addMethods:@[
            [NSObject dsp_classMethodNamed:@"copyWithZone:"]]
        ];
    }
}

@end

#pragma mark Reflection

@implementation NSObject (Reflection)

+ (DSPMirror *)dsp_reflection {
    return [DSPMirror reflect:self];
}

- (DSPMirror *)dsp_reflection {
    return [DSPMirror reflect:self];
}

/// Code borrowed from MAObjCRuntime by Mike Ash
+ (NSArray *)dsp_allSubclasses {
    return DSPGetAllSubclasses(self, YES);
}

- (Class)dsp_setClass:(Class)cls {
    return object_setClass(self, cls);
}

+ (Class)dsp_metaclass {
    return objc_getMetaClass(NSStringFromClass(self.class).UTF8String);
}

+ (size_t)dsp_instanceSize {
    return class_getInstanceSize(self.class);
}

+ (Class)dsp_setSuperclass:(Class)superclass {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return class_setSuperclass(self, superclass);
    #pragma clang diagnostic pop
}

+ (NSArray<Class> *)dsp_classHierarchy {
    return DSPGetClassHierarchy(self, YES);
}

+ (NSArray<DSPProtocol *> *)dsp_protocols {
    return DSPGetConformedProtocols(self);
}

@end


#pragma mark Methods

@implementation NSObject (Methods)

+ (NSArray<DSPMethod *> *)dsp_allMethods {
    NSMutableArray *instanceMethods = self.dsp_allInstanceMethods.mutableCopy;
    [instanceMethods addObjectsFromArray:self.dsp_allClassMethods];
    return instanceMethods;
}

+ (NSArray<DSPMethod *> *)dsp_allInstanceMethods {
    return DSPGetAllMethods(self, YES);
}

+ (NSArray<DSPMethod *> *)dsp_allClassMethods {
    return DSPGetAllMethods(self.dsp_metaclass, NO) ?: @[];
}

+ (DSPMethod *)dsp_methodNamed:(NSString *)name {
    Method m = class_getInstanceMethod([self class], NSSelectorFromString(name));
    if (m == NULL) {
        return nil;
    }

    return [DSPMethod method:m isInstanceMethod:YES];
}

+ (DSPMethod *)dsp_classMethodNamed:(NSString *)name {
    Method m = class_getClassMethod([self class], NSSelectorFromString(name));
    if (m == NULL) {
        return nil;
    }

    return [DSPMethod method:m isInstanceMethod:NO];
}

+ (BOOL)addMethod:(SEL)selector
     typeEncoding:(NSString *)typeEncoding
   implementation:(IMP)implementaiton
      toInstances:(BOOL)instance {
    return class_addMethod(instance ? self.class : self.dsp_metaclass, selector, implementaiton, typeEncoding.UTF8String);
}

+ (IMP)replaceImplementationOfMethod:(DSPMethodBase *)method with:(IMP)implementation useInstance:(BOOL)instance {
    return class_replaceMethod(instance ? self.class : self.dsp_metaclass, method.selector, implementation, method.typeEncoding.UTF8String);
}

+ (void)swizzle:(DSPMethodBase *)original with:(DSPMethodBase *)other onInstance:(BOOL)instance {
    [self swizzleBySelector:original.selector with:other.selector onInstance:instance];
}

+ (BOOL)swizzleByName:(NSString *)original with:(NSString *)other onInstance:(BOOL)instance {
    SEL originalMethod = NSSelectorFromString(original);
    SEL newMethod      = NSSelectorFromString(other);
    if (originalMethod == 0 || newMethod == 0) {
        return NO;
    }

    [self swizzleBySelector:originalMethod with:newMethod onInstance:instance];
    return YES;
}

+ (void)swizzleBySelector:(SEL)original with:(SEL)other onInstance:(BOOL)instance {
    Class cls = instance ? self.class : self.dsp_metaclass;
    Method originalMethod = class_getInstanceMethod(cls, original);
    Method newMethod = class_getInstanceMethod(cls, other);
    if (class_addMethod(cls, original, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(cls, other, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, newMethod);
    }
}

@end


#pragma mark Ivars

@implementation NSObject (Ivars)

+ (NSArray<DSPIvar *> *)dsp_allIvars {
    return DSPGetAllIvars(self);
}

+ (DSPIvar *)dsp_ivarNamed:(NSString *)name {
    Ivar i = class_getInstanceVariable([self class], name.UTF8String);
    if (i == NULL) {
        return nil;
    }

    return [DSPIvar ivar:i];
}

#pragma mark Get address
- (void *)dsp_getIvarAddress:(DSPIvar *)ivar {
    return (uint8_t *)(__bridge void *)self + ivar.offset;
}

- (void *)dsp_getObjcIvarAddress:(Ivar)ivar {
    return (uint8_t *)(__bridge void *)self + ivar_getOffset(ivar);
}

- (void *)dsp_getIvarAddressByName:(NSString *)name {
    Ivar ivar = class_getInstanceVariable(self.class, name.UTF8String);
    if (!ivar) return 0;
    
    return (uint8_t *)(__bridge void *)self + ivar_getOffset(ivar);
}

#pragma mark Set ivar object
- (void)dsp_setIvar:(DSPIvar *)ivar object:(id)value {
    object_setIvar(self, ivar.objc_ivar, value);
}

- (BOOL)dsp_setIvarByName:(NSString *)name object:(id)value {
    Ivar ivar = class_getInstanceVariable(self.class, name.UTF8String);
    if (!ivar) return NO;
    
    object_setIvar(self, ivar, value);
    return YES;
}

- (void)dsp_setObjcIvar:(Ivar)ivar object:(id)value {
    object_setIvar(self, ivar, value);
}

#pragma mark Set ivar value
- (void)dsp_setIvar:(DSPIvar *)ivar value:(void *)value size:(size_t)size {
    void *address = [self dsp_getIvarAddress:ivar];
    memcpy(address, value, size);
}

- (BOOL)dsp_setIvarByName:(NSString *)name value:(void *)value size:(size_t)size {
    Ivar ivar = class_getInstanceVariable(self.class, name.UTF8String);
    if (!ivar) return NO;
    
    [self dsp_setObjcIvar:ivar value:value size:size];
    return YES;
}

- (void)dsp_setObjcIvar:(Ivar)ivar value:(void *)value size:(size_t)size {
    void *address = [self dsp_getObjcIvarAddress:ivar];
    memcpy(address, value, size);
}

@end


#pragma mark Properties

@implementation NSObject (Properties)

+ (NSArray<DSPProperty *> *)dsp_allProperties {
    NSMutableArray *instanceProperties = self.dsp_allInstanceProperties.mutableCopy;
    [instanceProperties addObjectsFromArray:self.dsp_allClassProperties];
    return instanceProperties;
}

+ (NSArray<DSPProperty *> *)dsp_allInstanceProperties {
    return DSPGetAllProperties(self);
}

+ (NSArray<DSPProperty *> *)dsp_allClassProperties {
    return DSPGetAllProperties(self.dsp_metaclass) ?: @[];
}

+ (DSPProperty *)dsp_propertyNamed:(NSString *)name {
    objc_property_t p = class_getProperty([self class], name.UTF8String);
    if (p == NULL) {
        return nil;
    }

    return [DSPProperty property:p onClass:self];
}

+ (DSPProperty *)dsp_classPropertyNamed:(NSString *)name {
    objc_property_t p = class_getProperty(object_getClass(self), name.UTF8String);
    if (p == NULL) {
        return nil;
    }

    return [DSPProperty property:p onClass:object_getClass(self)];
}

+ (void)dsp_replaceProperty:(DSPProperty *)property {
    [self dsp_replaceProperty:property.name attributes:property.attributes];
}

+ (void)dsp_replaceProperty:(NSString *)name attributes:(DSPPropertyAttributes *)attributes {
    unsigned int count;
    objc_property_attribute_t *objc_attributes = [attributes copyAttributesList:&count];
    class_replaceProperty([self class], name.UTF8String, objc_attributes, count);
    free(objc_attributes);
}

@end


