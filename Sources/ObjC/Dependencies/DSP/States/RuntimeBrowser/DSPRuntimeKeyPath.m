#import "DSPRuntimeKeyPath.h"
#import "DSPRuntimeClient.h"

@interface DSPRuntimeKeyPath () {
    NSString *dsp_description;
}
@end

@implementation DSPRuntimeKeyPath

+ (instancetype)empty {
    static DSPRuntimeKeyPath *empty = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DSPSearchToken *any = DSPSearchToken.any;

        empty = [self new];
        empty->_bundleKey = any;
        empty->dsp_description = @"";
    });

    return empty;
}

+ (instancetype)bundle:(DSPSearchToken *)bundle
                 class:(DSPSearchToken *)cls
                method:(DSPSearchToken *)method
            isInstance:(NSNumber *)instance
                string:(NSString *)keyPathString {
    DSPRuntimeKeyPath *keyPath  = [self new];
    keyPath->_bundleKey = bundle;
    keyPath->_classKey  = cls;
    keyPath->_methodKey = method;

    keyPath->_instanceMethods = instance;

    // Remove irrelevant trailing '*' for equality purposes
    if ([keyPathString hasSuffix:@"*"]) {
        keyPathString = [keyPathString substringToIndex:keyPathString.length];
    }
    keyPath->dsp_description = keyPathString;
    
    if (bundle.isAny && cls.isAny && method.isAny) {
        [DSPRuntimeClient initializeWebKitLegacy];
    }

    return keyPath;
}

- (NSString *)description {
    return dsp_description;
}

- (NSUInteger)hash {
    return dsp_description.hash;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[DSPRuntimeKeyPath class]]) {
        DSPRuntimeKeyPath *kp = object;
        return [dsp_description isEqualToString:kp->dsp_description];
    }

    return NO;
}

@end
