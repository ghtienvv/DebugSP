#import "DSPObjectRef.h"
#import "DSPRuntimeUtility.h"
#import "NSArray+DSP.h"

@interface DSPObjectRef () {
    /// Used to retain the object if desired
    id _retainer;
}
@property (nonatomic, readonly) BOOL wantsSummary;
@end

@implementation DSPObjectRef
@synthesize summary = _summary;

+ (instancetype)unretained:(__unsafe_unretained id)object {
    return [self referencing:object showSummary:YES retained:NO];
}

+ (instancetype)unretained:(__unsafe_unretained id)object ivar:(NSString *)ivarName {
    return [[self alloc] initWithObject:object ivarName:ivarName showSummary:YES retained:NO];
}

+ (instancetype)retained:(id)object {
    return [self referencing:object showSummary:YES retained:YES];
}

+ (instancetype)retained:(id)object ivar:(NSString *)ivarName {
    return [[self alloc] initWithObject:object ivarName:ivarName showSummary:YES retained:YES];
}

+ (instancetype)referencing:(__unsafe_unretained id)object retained:(BOOL)retain {
    return retain ? [self retained:object] : [self unretained:object];
}

+ (instancetype)referencing:(__unsafe_unretained id)object ivar:(NSString *)ivarName retained:(BOOL)retain {
    return retain ? [self retained:object ivar:ivarName] : [self unretained:object ivar:ivarName];
}

+ (instancetype)referencing:(__unsafe_unretained id)object showSummary:(BOOL)showSummary retained:(BOOL)retain {
    return [[self alloc] initWithObject:object ivarName:nil showSummary:showSummary retained:retain];
}

+ (NSArray<DSPObjectRef *> *)referencingAll:(NSArray *)objects retained:(BOOL)retain {
    return [objects dsp_mapped:^id(id obj, NSUInteger idx) {
        return [self referencing:obj showSummary:YES retained:retain];
    }];
}

+ (NSArray<DSPObjectRef *> *)referencingClasses:(NSArray<Class> *)classes {
    return [classes dsp_mapped:^id(id obj, NSUInteger idx) {
        return [self referencing:obj showSummary:NO retained:NO];
    }];
}

- (id)initWithObject:(__unsafe_unretained id)object
            ivarName:(NSString *)ivar
         showSummary:(BOOL)showSummary
            retained:(BOOL)retain {
    self = [super init];
    if (self) {
        _object = object;
        _wantsSummary = showSummary;
        
        if (retain) {
            _retainer = object;
        }

        NSString *class = [DSPRuntimeUtility safeClassNameForObject:object];
        if (ivar) {
            _reference = [NSString stringWithFormat:@"%@ %@", class, ivar];
        } else if (showSummary) {
            _reference = [NSString stringWithFormat:@"%@ %p", class, object];
        } else {
            _reference = class;
        }
    }

    return self;
}

- (NSString *)summary {
    if (self.wantsSummary) {
        if (!_summary) {
            _summary = [DSPRuntimeUtility summaryForObject:self.object];
        }
        
        return _summary;
    }
    else {
        return nil;
    }
}

- (void)retainObject {
    if (!_retainer) {
        _retainer = _object;
    }
}

- (void)releaseObject {
    _retainer = nil;
}

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@: %@>",
        [self class], self.reference
    ];
}

@end
