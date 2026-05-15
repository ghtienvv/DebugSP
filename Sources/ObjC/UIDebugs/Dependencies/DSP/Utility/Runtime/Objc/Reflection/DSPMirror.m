#import "DSPMirror.h"
#import "DSPProperty.h"
#import "DSPMethod.h"
#import "DSPIvar.h"
#import "DSPProtocol.h"
#import "DSPUtility.h"


#pragma mark DSPMirror

@implementation DSPMirror

- (id)init {
    [NSException
        raise:NSInternalInconsistencyException
        format:@"Class instance should not be created with -init"
    ];
    return nil;
}

#pragma mark Initialization
+ (instancetype)reflect:(id)objectOrClass {
    return [[self alloc] initWithSubject:objectOrClass];
}

- (id)initWithSubject:(id)objectOrClass {
    NSParameterAssert(objectOrClass);
    
    self = [super init];
    if (self) {
        _value = objectOrClass;
        [self examine];
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %@=%@>",
        NSStringFromClass(self.class),
        self.isClass ? @"metaclass" : @"class",
        self.className
    ];
}

- (void)examine {
    BOOL isClass = object_isClass(self.value);
    Class cls  = isClass ? self.value : object_getClass(self.value);
    Class meta = object_getClass(cls);
    _className = NSStringFromClass(cls);
    _isClass   = isClass;
    
    unsigned int pcount, cpcount, mcount, cmcount, ivcount, pccount;
    Ivar *objcIvars                       = class_copyIvarList(cls, &ivcount);
    Method *objcMethods                   = class_copyMethodList(cls, &mcount);
    Method *objcClsMethods                = class_copyMethodList(meta, &cmcount);
    objc_property_t *objcProperties       = class_copyPropertyList(cls, &pcount);
    objc_property_t *objcClsProperties    = class_copyPropertyList(meta, &cpcount);
    Protocol *__unsafe_unretained *protos = class_copyProtocolList(cls, &pccount);
    
    _ivars = [NSArray dsp_forEachUpTo:ivcount map:^id(NSUInteger i) {
        return [DSPIvar ivar:objcIvars[i]];
    }];
    
    _methods = [NSArray dsp_forEachUpTo:mcount map:^id(NSUInteger i) {
        return [DSPMethod method:objcMethods[i] isInstanceMethod:YES];
    }];
    _classMethods = [NSArray dsp_forEachUpTo:cmcount map:^id(NSUInteger i) {
        return [DSPMethod method:objcClsMethods[i] isInstanceMethod:NO];
    }];
    
    _properties = [NSArray dsp_forEachUpTo:pcount map:^id(NSUInteger i) {
        return [DSPProperty property:objcProperties[i] onClass:cls];
    }];
    _classProperties = [NSArray dsp_forEachUpTo:cpcount map:^id(NSUInteger i) {
        return [DSPProperty property:objcClsProperties[i] onClass:meta];
    }];
    
    _protocols = [NSArray dsp_forEachUpTo:pccount map:^id(NSUInteger i) {
        return [DSPProtocol protocol:protos[i]];
    }];
    
    // Cleanup
    free(objcClsProperties);
    free(objcProperties);
    free(objcClsMethods);
    free(objcMethods);
    free(objcIvars);
    free(protos);
    protos = NULL;
}

#pragma mark Misc

- (DSPMirror *)superMirror {
    Class cls = _isClass ? _value : object_getClass(_value);
    return [DSPMirror reflect:class_getSuperclass(cls)];
}

@end


#pragma mark ExtendedMirror

@implementation DSPMirror (ExtendedMirror)

- (id)filter:(NSArray *)array forName:(NSString *)name {
    NSPredicate *filter = [NSPredicate predicateWithFormat:@"%K = %@", @"name", name];
    return [array filteredArrayUsingPredicate:filter].firstObject;
}

- (DSPMethod *)methodNamed:(NSString *)name {
    return [self filter:self.methods forName:name];
}

- (DSPMethod *)classMethodNamed:(NSString *)name {
    return [self filter:self.classMethods forName:name];
}

- (DSPProperty *)propertyNamed:(NSString *)name {
    return [self filter:self.properties forName:name];
}

- (DSPProperty *)classPropertyNamed:(NSString *)name {
    return [self filter:self.classProperties forName:name];
}

- (DSPIvar *)ivarNamed:(NSString *)name {
    return [self filter:self.ivars forName:name];
}

- (DSPProtocol *)protocolNamed:(NSString *)name {
    return [self filter:self.protocols forName:name];
}

@end
