#import "DSPClassBuilder.h"
#import "DSPProperty.h"
#import "DSPMethodBase.h"
#import "DSPProtocol.h"
#import <objc/runtime.h>


#pragma mark DSPClassBuilder

@interface DSPClassBuilder ()
@property (nonatomic) NSString *name;
@end

@implementation DSPClassBuilder

- (id)init {
    [NSException
        raise:NSInternalInconsistencyException
        format:@"Class instance should not be created with -init"
    ];
    return nil;
}

#pragma mark Initializers
+ (instancetype)allocateClass:(NSString *)name {
    return [self allocateClass:name superclass:NSObject.class];
}

+ (instancetype)allocateClass:(NSString *)name superclass:(Class)superclass {
    return [self allocateClass:name superclass:superclass extraBytes:0];
}

+ (instancetype)allocateClass:(NSString *)name superclass:(Class)superclass extraBytes:(size_t)bytes {
    NSParameterAssert(name);
    return [[self alloc] initWithClass:objc_allocateClassPair(superclass, name.UTF8String, bytes)];
}

+ (instancetype)allocateRootClass:(NSString *)name {
    NSParameterAssert(name);
    return [[self alloc] initWithClass:objc_allocateClassPair(Nil, name.UTF8String, 0)];
}

+ (instancetype)builderForClass:(Class)cls {
    return [[self alloc] initWithClass:cls];
}

- (id)initWithClass:(Class)cls {
    NSParameterAssert(cls);
    
    self = [super init];
    if (self) {
        _workingClass = cls;
        _name = NSStringFromClass(_workingClass);
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ name=%@, registered=%d>",
            NSStringFromClass(self.class), self.name, self.isRegistered];
}

#pragma mark Building
- (NSArray *)addMethods:(NSArray *)methods {
    NSParameterAssert(methods.count);
    
    NSMutableArray *failed = [NSMutableArray new];
    for (DSPMethodBase *m in methods) {
        if (!class_addMethod(self.workingClass, m.selector, m.implementation, m.typeEncoding.UTF8String)) {
            [failed addObject:m];
        }
    }
    
    return failed;
}

- (NSArray *)addProperties:(NSArray *)properties {
    NSParameterAssert(properties.count);
    
    NSMutableArray *failed = [NSMutableArray new];
    for (DSPProperty *p in properties) {
        unsigned int pcount;
        objc_property_attribute_t *attributes = [p copyAttributesList:&pcount];
        if (!class_addProperty(self.workingClass, p.name.UTF8String, attributes, pcount)) {
            [failed addObject:p];
        }
        free(attributes);
    }
    
    return failed;
}

- (NSArray *)addProtocols:(NSArray *)protocols {
    NSParameterAssert(protocols.count);
    
    NSMutableArray *failed = [NSMutableArray new];
    for (DSPProtocol *p in protocols) {
        if (!class_addProtocol(self.workingClass, p.objc_protocol)) {
            [failed addObject:p];
        }
    }
    
    return failed;
}

- (NSArray *)addIvars:(NSArray *)ivars {
    NSParameterAssert(ivars.count);
    
    NSMutableArray *failed = [NSMutableArray new];
    for (DSPIvarBuilder *ivar in ivars) {
        if (!class_addIvar(self.workingClass, ivar.name.UTF8String, ivar.size, ivar.alignment, ivar.encoding.UTF8String)) {
            [failed addObject:ivar];
        }
    }
    
    return failed;
}

- (Class)registerClass {
    if (self.isRegistered) {
        [NSException raise:NSInternalInconsistencyException format:@"Class is already registered"];
    }
    
    objc_registerClassPair(self.workingClass);
    return self.workingClass;
}

- (BOOL)isRegistered {
    return objc_lookUpClass(self.name.UTF8String) != nil;
}

@end


#pragma mark DSPIvarBuilder

@implementation DSPIvarBuilder

+ (instancetype)name:(NSString *)name size:(size_t)size alignment:(uint8_t)alignment typeEncoding:(NSString *)encoding {
    return [[self alloc] initWithName:name size:size alignment:alignment typeEncoding:encoding];
}

- (id)initWithName:(NSString *)name size:(size_t)size alignment:(uint8_t)alignment typeEncoding:(NSString *)encoding {
    NSParameterAssert(name); NSParameterAssert(encoding);
    NSParameterAssert(size > 0); NSParameterAssert(alignment > 0);
    
    self = [super init];
    if (self) {
        _name      = name;
        _encoding  = encoding;
        _size      = size;
        _alignment = alignment;
    }
    
    return self;
}

@end
