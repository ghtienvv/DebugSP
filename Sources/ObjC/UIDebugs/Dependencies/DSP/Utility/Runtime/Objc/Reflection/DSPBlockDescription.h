#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, DSPBlockOptions) {
   DSPBlockOptionHasCopyDispose = (1 << 25),
   DSPBlockOptionHasCtor        = (1 << 26), // helpers have C++ code
   DSPBlockOptionIsGlobal       = (1 << 28),
   DSPBlockOptionHasStret       = (1 << 29), // IFF BLOCK_HAS_SIGNATURE
   DSPBlockOptionHasSignature   = (1 << 30),
};

NS_ASSUME_NONNULL_BEGIN

#pragma mark -
@interface DSPBlockDescription : NSObject

+ (instancetype)describing:(id)block;

@property (nonatomic, readonly, nullable) NSMethodSignature *signature;
@property (nonatomic, readonly, nullable) NSString *signatureString;
@property (nonatomic, readonly, nullable) NSString *sourceDeclaration;
@property (nonatomic, readonly) DSPBlockOptions flags;
@property (nonatomic, readonly) NSUInteger size;
@property (nonatomic, readonly) NSString *summary;
@property (nonatomic, readonly) id block;

- (BOOL)isCompatibleForBlockSwizzlingWithMethodSignature:(NSMethodSignature *)methodSignature;

@end

#pragma mark -
@interface NSBlock : NSObject
- (void)invoke;
@end

NS_ASSUME_NONNULL_END
