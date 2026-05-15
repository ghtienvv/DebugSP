#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#pragma mark - Classes

extern NSUInteger const kDSPKnownUnsafeClassCount;
extern const Class * DSPKnownUnsafeClassList(void);
extern NSSet * DSPKnownUnsafeClassNames(void);
extern CFSetRef DSPKnownUnsafeClasses;

static Class cNSObject = nil, cNSProxy = nil;

__attribute__((constructor))
static void DSPInitKnownRootClasses(void) {
    cNSObject = [NSObject class];
    cNSProxy = [NSProxy class];
}

static inline BOOL DSPClassIsSafe(Class cls) {
    // Is it nil or known to be unsafe?
    if (!cls || CFSetContainsValue(DSPKnownUnsafeClasses, (__bridge void *)cls)) {
        return NO;
    }
    
    // Is it a known root class?
    if (!class_getSuperclass(cls)) {
        return cls == cNSObject || cls == cNSProxy;
    }
    
    // Probably safe
    return YES;
}

static inline BOOL DSPClassNameIsSafe(NSString *cls) {
    if (!cls) return NO;
    
    NSSet *ignored = DSPKnownUnsafeClassNames();
    return ![ignored containsObject:cls];
}

#pragma mark - Ivars

extern CFSetRef DSPKnownUnsafeIvars;

static inline BOOL DSPIvarIsSafe(Ivar ivar) {
    if (!ivar) return NO;

    return !CFSetContainsValue(DSPKnownUnsafeIvars, ivar);
}
