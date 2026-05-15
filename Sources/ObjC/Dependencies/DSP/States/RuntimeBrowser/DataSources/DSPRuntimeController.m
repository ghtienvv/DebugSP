#import "DSPRuntimeController.h"
#import "DSPRuntimeClient.h"
#import "DSPMethod.h"

@interface DSPRuntimeController ()
@property (nonatomic, readonly) NSCache *bundlePathsCache;
@property (nonatomic, readonly) NSCache *bundleNamesCache;
@property (nonatomic, readonly) NSCache *classNamesCache;
@property (nonatomic, readonly) NSCache *methodsCache;
@end

@implementation DSPRuntimeController

#pragma mark Initialization

static DSPRuntimeController *controller = nil;
+ (instancetype)shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        controller = [self new];
    });

    return controller;
}

- (id)init {
    self = [super init];
    if (self) {
        _bundlePathsCache = [NSCache new];
        _bundleNamesCache = [NSCache new];
        _classNamesCache  = [NSCache new];
        _methodsCache     = [NSCache new];
    }

    return self;
}

#pragma mark Public

+ (NSArray *)dataForKeyPath:(DSPRuntimeKeyPath *)keyPath {
    if (keyPath.bundleKey) {
        if (keyPath.classKey) {
            if (keyPath.methodKey) {
                return [[self shared] methodsForKeyPath:keyPath];
            } else {
                return [[self shared] classesForKeyPath:keyPath];
            }
        } else {
            return [[self shared] bundleNamesForToken:keyPath.bundleKey];
        }
    } else {
        return @[];
    }
}

+ (NSArray<NSArray<DSPMethod *> *> *)methodsForToken:(DSPSearchToken *)token
                         instance:(NSNumber *)inst
                        inClasses:(NSArray<NSString*> *)classes {
    return [DSPRuntimeClient.runtime
        methodsForToken:token
        instance:inst
        inClasses:classes
    ];
}

+ (NSMutableArray<NSString *> *)classesForKeyPath:(DSPRuntimeKeyPath *)keyPath {
    return [[self shared] classesForKeyPath:keyPath];
}

+ (NSString *)shortBundleNameForClass:(NSString *)name {
    const char *imageName = class_getImageName(NSClassFromString(name));
    if (!imageName) {
        return @"(unspecified)";
    }
    
    return [DSPRuntimeClient.runtime shortNameForImageName:@(imageName)];
}

+ (NSString *)imagePathWithShortName:(NSString *)suffix {
    return [DSPRuntimeClient.runtime imageNameForShortName:suffix];
}

+ (NSArray *)allBundleNames {
    return DSPRuntimeClient.runtime.imageDisplayNames;
}

#pragma mark Private

- (NSMutableArray *)bundlePathsForToken:(DSPSearchToken *)token {
    // Only cache if no wildcard
    BOOL shouldCache = token == TBWildcardOptionsNone;

    if (shouldCache) {
        NSMutableArray<NSString*> *cached = [self.bundlePathsCache objectForKey:token];
        if (cached) {
            return cached;
        }

        NSMutableArray<NSString*> *bundles = [DSPRuntimeClient.runtime bundlePathsForToken:token];
        [self.bundlePathsCache setObject:bundles forKey:token];
        return bundles;
    }
    else {
        return [DSPRuntimeClient.runtime bundlePathsForToken:token];
    }
}

- (NSMutableArray<NSString *> *)bundleNamesForToken:(DSPSearchToken *)token {
    // Only cache if no wildcard
    BOOL shouldCache = token == TBWildcardOptionsNone;

    if (shouldCache) {
        NSMutableArray<NSString*> *cached = [self.bundleNamesCache objectForKey:token];
        if (cached) {
            return cached;
        }

        NSMutableArray<NSString*> *bundles = [DSPRuntimeClient.runtime bundleNamesForToken:token];
        [self.bundleNamesCache setObject:bundles forKey:token];
        return bundles;
    }
    else {
        return [DSPRuntimeClient.runtime bundleNamesForToken:token];
    }
}

- (NSMutableArray<NSString *> *)classesForKeyPath:(DSPRuntimeKeyPath *)keyPath {
    DSPSearchToken *classToken = keyPath.classKey;
    DSPSearchToken *bundleToken = keyPath.bundleKey;
    
    // Only cache if no wildcard
    BOOL shouldCache = bundleToken.options == 0 && classToken.options == 0;
    NSString *key = nil;

    if (shouldCache) {
        key = [@[bundleToken.description, classToken.description] componentsJoinedByString:@"+"];
        NSMutableArray<NSString *> *cached = [self.classNamesCache objectForKey:key];
        if (cached) {
            return cached;
        }
    }

    NSMutableArray<NSString *> *bundles = [self bundlePathsForToken:bundleToken];
    NSMutableArray<NSString *> *classes = [DSPRuntimeClient.runtime
        classesForToken:classToken inBundles:bundles
    ];

    if (shouldCache) {
        [self.classNamesCache setObject:classes forKey:key];
    }

    return classes;
}

- (NSArray<NSMutableArray<DSPMethod *> *> *)methodsForKeyPath:(DSPRuntimeKeyPath *)keyPath {
    // Only cache if no wildcard, but check cache anyway bc I'm lazy
    NSArray<NSMutableArray *> *cached = [self.methodsCache objectForKey:keyPath];
    if (cached) {
        return cached;
    }

    NSArray<NSString *> *classes = [self classesForKeyPath:keyPath];
    NSArray<NSMutableArray<DSPMethod *> *> *methodLists = [DSPRuntimeClient.runtime
        methodsForToken:keyPath.methodKey
        instance:keyPath.instanceMethods
        inClasses:classes
    ];

    for (NSMutableArray<DSPMethod *> *methods in methodLists) {
        [methods sortUsingComparator:^NSComparisonResult(DSPMethod *m1, DSPMethod *m2) {
            return [m1.description caseInsensitiveCompare:m2.description];
        }];
    }

    // Only cache if no wildcard, otherwise the cache could grow very large
    if (keyPath.bundleKey.isAbsolute &&
        keyPath.classKey.isAbsolute) {
        [self.methodsCache setObject:methodLists forKey:keyPath];
    }

    return methodLists;
}

@end
