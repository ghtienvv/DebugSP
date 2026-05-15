#import "DSPBlockDescription.h"
#import "DSPRuntimeUtility.h"

struct block_object {
    void *isa;
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct block_descriptor {
        unsigned long int reserved;    // NULL
        unsigned long int size;     // sizeof(struct Block_literal_1)
        // optional helper functions
        void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
        void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                         // IFF (1<<30)
    } *descriptor;
    // imported variables
};

@implementation DSPBlockDescription

+ (instancetype)describing:(id)block {
    return [[self alloc] initWithObjcBlock:block];
}

- (id)initWithObjcBlock:(id)block {
    self = [super init];
    if (self) {
        _block = block;
        
        struct block_object *blockRef = (__bridge struct block_object *)block;
        _flags = blockRef->flags;
        _size = blockRef->descriptor->size;
        
        if (_flags & DSPBlockOptionHasSignature) {
            void *signatureLocation = blockRef->descriptor;
            signatureLocation += sizeof(unsigned long int);
            signatureLocation += sizeof(unsigned long int);
            
            if (_flags & DSPBlockOptionHasCopyDispose) {
                signatureLocation += sizeof(void(*)(void *dst, void *src));
                signatureLocation += sizeof(void (*)(void *src));
            }
            
            const char *signature = (*(const char **)signatureLocation);
            _signatureString = @(signature);
            
            @try {
                _signature = [NSMethodSignature signatureWithObjCTypes:signature];
            } @catch (NSException *exception) { }
        }
        
        NSMutableString *summary = [NSMutableString stringWithFormat:
            @"Type signature: %@\nSize: %@\nIs global: %@\nHas constructor: %@\nIs stret: %@",
            self.signatureString ?: @"nil", @(self.size),
            @((BOOL)(_flags & DSPBlockOptionIsGlobal)),
            @((BOOL)(_flags & DSPBlockOptionHasCtor)),
            @((BOOL)(_flags & DSPBlockOptionHasStret))
        ];
        
        if (!self.signature) {
            [summary appendFormat:@"\nNumber of arguments: %@", @(self.signature.numberOfArguments)];
        }
        
        _summary = summary.copy;
        _sourceDeclaration = [self buildLikelyDeclaration];
    }
    
    return self;
}

- (BOOL)isCompatibleForBlockSwizzlingWithMethodSignature:(NSMethodSignature *)methodSignature {
    if (!self.signature) {
        return NO;
    }
    
    if (self.signature.numberOfArguments != methodSignature.numberOfArguments + 1) {
        return NO;
    }
    
    if (strcmp(self.signature.methodReturnType, methodSignature.methodReturnType) != 0) {
        return NO;
    }
    
    for (int i = 0; i < methodSignature.numberOfArguments; i++) {
        if (i == 1) {
            // SEL in method, IMP in block
            if (strcmp([methodSignature getArgumentTypeAtIndex:i], ":") != 0) {
                return NO;
            }
            
            if (strcmp([self.signature getArgumentTypeAtIndex:i + 1], "^?") != 0) {
                return NO;
            }
        } else {
            if (strcmp([self.signature getArgumentTypeAtIndex:i], [self.signature getArgumentTypeAtIndex:i + 1]) != 0) {
                return NO;
            }
        }
    }
    
    return YES;
}

- (NSString *)buildLikelyDeclaration {
    NSMethodSignature *signature = self.signature;
    NSUInteger numberOfArguments = signature.numberOfArguments;
    const char *returnType       = signature.methodReturnType;
    
    // Return type
    NSMutableString *decl = [NSMutableString stringWithString:@"^"];
    if (returnType[0] != DSPTypeEncodingVoid) {
        [decl appendString:[DSPRuntimeUtility readableTypeForEncoding:@(returnType)]];
        [decl appendString:@" "];
    }
    
    // Arguments
    if (numberOfArguments) {
        [decl appendString:@"("];
        for (NSUInteger i = 1; i < numberOfArguments; i++) {
            const char *argType = [self.signature getArgumentTypeAtIndex:i] ?: "?";
            NSString *readableArgType = [DSPRuntimeUtility readableTypeForEncoding:@(argType)];
            [decl appendFormat:@"%@ arg%@, ", readableArgType, @(i)];
        }
        
        [decl deleteCharactersInRange:NSMakeRange(decl.length-2, 2)];
        [decl appendString:@")"];
    }
    
    return decl.copy;
}

@end
