#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#define DSPEncodeClass(class) ("@\"" #class "\"")
#define DSPEncodeObject(obj) (obj ? [NSString stringWithFormat:@"@\"%@\"", [obj class]].UTF8String : @encode(id))

// Arguments 0 and 1 are self and _cmd always
extern const unsigned int kDSPNumberOfImplicitArgs;

// See https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW6
extern NSString *const kDSPPropertyAttributeKeyTypeEncoding;
extern NSString *const kDSPPropertyAttributeKeyBackingIvarName;
extern NSString *const kDSPPropertyAttributeKeyReadOnly;
extern NSString *const kDSPPropertyAttributeKeyCopy;
extern NSString *const kDSPPropertyAttributeKeyRetain;
extern NSString *const kDSPPropertyAttributeKeyNonAtomic;
extern NSString *const kDSPPropertyAttributeKeyCustomGetter;
extern NSString *const kDSPPropertyAttributeKeyCustomSetter;
extern NSString *const kDSPPropertyAttributeKeyDynamic;
extern NSString *const kDSPPropertyAttributeKeyWeak;
extern NSString *const kDSPPropertyAttributeKeyGarbageCollectable;
extern NSString *const kDSPPropertyAttributeKeyOldStyleTypeEncoding;

typedef NS_ENUM(NSUInteger, DSPPropertyAttribute) {
    DSPPropertyAttributeTypeEncoding       = 'T',
    DSPPropertyAttributeBackingIvarName    = 'V',
    DSPPropertyAttributeCopy               = 'C',
    DSPPropertyAttributeCustomGetter       = 'G',
    DSPPropertyAttributeCustomSetter       = 'S',
    DSPPropertyAttributeDynamic            = 'D',
    DSPPropertyAttributeGarbageCollectible = 'P',
    DSPPropertyAttributeNonAtomic          = 'N',
    DSPPropertyAttributeOldTypeEncoding    = 't',
    DSPPropertyAttributeReadOnly           = 'R',
    DSPPropertyAttributeRetain             = '&',
    DSPPropertyAttributeWeak               = 'W'
}; //NS_SWIFT_NAME(DSP.PropertyAttribute);

typedef NS_ENUM(char, DSPTypeEncoding) {
    DSPTypeEncodingNull             = '\0',
    DSPTypeEncodingUnknown          = '?',
    DSPTypeEncodingChar             = 'c',
    DSPTypeEncodingInt              = 'i',
    DSPTypeEncodingShort            = 's',
    DSPTypeEncodingLong             = 'l',
    DSPTypeEncodingLongLong         = 'q',
    DSPTypeEncodingUnsignedChar     = 'C',
    DSPTypeEncodingUnsignedInt      = 'I',
    DSPTypeEncodingUnsignedShort    = 'S',
    DSPTypeEncodingUnsignedLong     = 'L',
    DSPTypeEncodingUnsignedLongLong = 'Q',
    DSPTypeEncodingFloat            = 'f',
    DSPTypeEncodingDouble           = 'd',
    DSPTypeEncodingLongDouble       = 'D',
    DSPTypeEncodingCBool            = 'B',
    DSPTypeEncodingVoid             = 'v',
    DSPTypeEncodingCString          = '*',
    DSPTypeEncodingObjcObject       = '@',
    DSPTypeEncodingObjcClass        = '#',
    DSPTypeEncodingSelector         = ':',
    DSPTypeEncodingArrayBegin       = '[',
    DSPTypeEncodingArrayEnd         = ']',
    DSPTypeEncodingStructBegin      = '{',
    DSPTypeEncodingStructEnd        = '}',
    DSPTypeEncodingUnionBegin       = '(',
    DSPTypeEncodingUnionEnd         = ')',
    DSPTypeEncodingQuote            = '\"',
    DSPTypeEncodingBitField         = 'b',
    DSPTypeEncodingPointer          = '^',
    DSPTypeEncodingConst            = 'r'
};
