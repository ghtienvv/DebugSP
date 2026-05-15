#import "DSPRuntimeConstants.h"

@interface NSString (DSPTypeEncoding)

///@return whether this type starts with the const specifier
@property (nonatomic, readonly) BOOL dsp_typeIsConst;
/// @return the first char in the type encoding that is not the const specifier
@property (nonatomic, readonly) DSPTypeEncoding dsp_firstNonConstType;
/// @return the first char in the type encoding after the pointer specifier, if it is a pointer
@property (nonatomic, readonly) DSPTypeEncoding dsp_pointeeType;
/// @return whether this type is an objc object of any kind, even if it's const
@property (nonatomic, readonly) BOOL dsp_typeIsObjectOrClass;
/// @return the class named in this type encoding if it is of the form \c @"MYClass"
@property (nonatomic, readonly) Class dsp_typeClass;
/// Includes C strings and selectors as well as regular pointers
@property (nonatomic, readonly) BOOL dsp_typeIsNonObjcPointer;

@end

@interface NSString (KeyPaths)

- (NSString *)dsp_stringByRemovingLastKeyPathComponent;
- (NSString *)dsp_stringByReplacingLastKeyPathComponent:(NSString *)replacement;

@end
