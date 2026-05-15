#import "DSPPropertyAttributes.h"
#import "DSPRuntimeUtility.h"
#import "NSString+ObjcRuntime.h"
#import "NSDictionary+ObjcRuntime.h"


#pragma mark DSPPropertyAttributes

@interface DSPPropertyAttributes ()

@property (nonatomic) NSString *backingIvar;
@property (nonatomic) NSString *typeEncoding;
@property (nonatomic) NSString *oldTypeEncoding;
@property (nonatomic) SEL customGetter;
@property (nonatomic) SEL customSetter;
@property (nonatomic) BOOL isReadOnly;
@property (nonatomic) BOOL isCopy;
@property (nonatomic) BOOL isRetained;
@property (nonatomic) BOOL isNonatomic;
@property (nonatomic) BOOL isDynamic;
@property (nonatomic) BOOL isWeak;
@property (nonatomic) BOOL isGarbageCollectable;

- (NSString *)buildFullDeclaration;

@end

@implementation DSPPropertyAttributes
@synthesize list = _list;

#pragma mark Initializers

+ (instancetype)attributesForProperty:(objc_property_t)property {
    return [self attributesFromDictionary:[NSDictionary attributesDictionaryForProperty:property]];
}

+ (instancetype)attributesFromDictionary:(NSDictionary *)attributes {
    return [[self alloc] initWithAttributesDictionary:attributes];
}

- (id)initWithAttributesDictionary:(NSDictionary *)attributes {
    NSParameterAssert(attributes);
    
    self = [super init];
    if (self) {
        _dictionary           = attributes;
        _string               = attributes.propertyAttributesString;
        _count                = attributes.count;
        _typeEncoding         = attributes[kDSPPropertyAttributeKeyTypeEncoding];
        _backingIvar          = attributes[kDSPPropertyAttributeKeyBackingIvarName];
        _oldTypeEncoding      = attributes[kDSPPropertyAttributeKeyOldStyleTypeEncoding];
        _customGetterString   = attributes[kDSPPropertyAttributeKeyCustomGetter];
        _customSetterString   = attributes[kDSPPropertyAttributeKeyCustomSetter];
        _customGetter         = NSSelectorFromString(_customGetterString);
        _customSetter         = NSSelectorFromString(_customSetterString);
        _isReadOnly           = attributes[kDSPPropertyAttributeKeyReadOnly] != nil;
        _isCopy               = attributes[kDSPPropertyAttributeKeyCopy] != nil;
        _isRetained           = attributes[kDSPPropertyAttributeKeyRetain] != nil;
        _isNonatomic          = attributes[kDSPPropertyAttributeKeyNonAtomic] != nil;
        _isWeak               = attributes[kDSPPropertyAttributeKeyWeak] != nil;
        _isGarbageCollectable = attributes[kDSPPropertyAttributeKeyGarbageCollectable] != nil;

        _fullDeclaration = [self buildFullDeclaration];
    }
    
    return self;
}

#pragma mark Misc

- (NSString *)description {
    return [NSString
        stringWithFormat:@"<%@ \"%@\", ivar=%@, readonly=%d, nonatomic=%d, getter=%@, setter=%@>",
        NSStringFromClass(self.class),
        self.string,
        self.backingIvar ?: @"none",
        self.isReadOnly,
        self.isNonatomic,
        NSStringFromSelector(self.customGetter) ?: @"none",
        NSStringFromSelector(self.customSetter) ?: @"none"
    ];
}

- (objc_property_attribute_t *)copyAttributesList:(unsigned int *)attributesCount {
    NSDictionary *attrs = self.string.propertyAttributes;
    objc_property_attribute_t *propertyAttributes = malloc(attrs.count * sizeof(objc_property_attribute_t));

    if (attributesCount) {
        *attributesCount = (unsigned int)attrs.count;
    }
    
    NSUInteger i = 0;
    for (NSString *key in attrs.allKeys) {
        DSPPropertyAttribute c = (DSPPropertyAttribute)[key characterAtIndex:0];
        switch (c) {
            case DSPPropertyAttributeTypeEncoding: {
                objc_property_attribute_t pa = {
                    kDSPPropertyAttributeKeyTypeEncoding.UTF8String,
                    self.typeEncoding.UTF8String
                };
                propertyAttributes[i] = pa;
                break;
            }
            case DSPPropertyAttributeBackingIvarName: {
                objc_property_attribute_t pa = {
                    kDSPPropertyAttributeKeyBackingIvarName.UTF8String,
                    self.backingIvar.UTF8String
                };
                propertyAttributes[i] = pa;
                break;
            }
            case DSPPropertyAttributeCopy: {
                objc_property_attribute_t pa = {kDSPPropertyAttributeKeyCopy.UTF8String, ""};
                propertyAttributes[i] = pa;
                break;
            }
            case DSPPropertyAttributeCustomGetter: {
                objc_property_attribute_t pa = {
                    kDSPPropertyAttributeKeyCustomGetter.UTF8String,
                    NSStringFromSelector(self.customGetter).UTF8String ?: ""
                };
                propertyAttributes[i] = pa;
                break;
            }
            case DSPPropertyAttributeCustomSetter: {
                objc_property_attribute_t pa = {
                    kDSPPropertyAttributeKeyCustomSetter.UTF8String,
                    NSStringFromSelector(self.customSetter).UTF8String ?: ""
                };
                propertyAttributes[i] = pa;
                break;
            }
            case DSPPropertyAttributeDynamic: {
                objc_property_attribute_t pa = {kDSPPropertyAttributeKeyDynamic.UTF8String, ""};
                propertyAttributes[i] = pa;
                break;
            }
            case DSPPropertyAttributeGarbageCollectible: {
                objc_property_attribute_t pa = {kDSPPropertyAttributeKeyGarbageCollectable.UTF8String, ""};
                propertyAttributes[i] = pa;
                break;
            }
            case DSPPropertyAttributeNonAtomic: {
                objc_property_attribute_t pa = {kDSPPropertyAttributeKeyNonAtomic.UTF8String, ""};
                propertyAttributes[i] = pa;
                break;
            }
            case DSPPropertyAttributeOldTypeEncoding: {
                objc_property_attribute_t pa = {
                    kDSPPropertyAttributeKeyOldStyleTypeEncoding.UTF8String,
                    self.oldTypeEncoding.UTF8String ?: ""
                };
                propertyAttributes[i] = pa;
                break;
            }
            case DSPPropertyAttributeReadOnly: {
                objc_property_attribute_t pa = {kDSPPropertyAttributeKeyReadOnly.UTF8String, ""};
                propertyAttributes[i] = pa;
                break;
            }
            case DSPPropertyAttributeRetain: {
                objc_property_attribute_t pa = {kDSPPropertyAttributeKeyRetain.UTF8String, ""};
                propertyAttributes[i] = pa;
                break;
            }
            case DSPPropertyAttributeWeak: {
                objc_property_attribute_t pa = {kDSPPropertyAttributeKeyWeak.UTF8String, ""};
                propertyAttributes[i] = pa;
                break;
            }
        }
        i++;
    }
    
    return propertyAttributes;
}

- (objc_property_attribute_t *)list {
    if (!_list) {
        _list = [self copyAttributesList:nil];
    }

    return _list;
}

- (NSString *)buildFullDeclaration {
    NSMutableString *decl = [NSMutableString new];

    [decl appendFormat:@"%@, ", _isNonatomic ? @"nonatomic" : @"atomic"];
    [decl appendFormat:@"%@, ", _isReadOnly ? @"readonly" : @"readwrite"];

    BOOL noExplicitMemorySemantics = YES;
    if (_isCopy) { noExplicitMemorySemantics = NO;
        [decl appendString:@"copy, "];
    }
    if (_isRetained) { noExplicitMemorySemantics = NO;
        [decl appendString:@"strong, "];
    }
    if (_isWeak) { noExplicitMemorySemantics = NO;
        [decl appendString:@"weak, "];
    }

    if ([_typeEncoding hasPrefix:@"@"] && noExplicitMemorySemantics) {
        // *probably* strong if this is an object; strong is the default.
        [decl appendString:@"strong, "];
    } else if (noExplicitMemorySemantics) {
        // *probably* assign if this is not an object
        [decl appendString:@"assign, "];
    }

    if (_customGetter) {
        [decl appendFormat:@"getter=%@, ", NSStringFromSelector(_customGetter)];
    }
    if (_customSetter) {
        [decl appendFormat:@"setter=%@, ", NSStringFromSelector(_customSetter)];
    }

    [decl deleteCharactersInRange:NSMakeRange(decl.length-2, 2)];
    return decl.copy;
}

- (void)dealloc {
    if (_list) {
        free(_list);
        _list = nil;
    }
}

#pragma mark Copying

- (id)copyWithZone:(NSZone *)zone {
    return [[DSPPropertyAttributes class] attributesFromDictionary:self.dictionary];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [[DSPMutablePropertyAttributes class] attributesFromDictionary:self.dictionary];
}

@end



#pragma mark DSPMutablePropertyAttributes

@interface DSPMutablePropertyAttributes ()
@property (nonatomic) BOOL countDelta;
@property (nonatomic) BOOL stringDelta;
@property (nonatomic) BOOL dictDelta;
@property (nonatomic) BOOL listDelta;
@property (nonatomic) BOOL declDelta;
@end

#define PropertyWithDeltaFlag(type, name, Name) @dynamic name; \
- (void)set ## Name:(type)name { \
    if (name != _ ## name) { \
        _countDelta = _stringDelta = _dictDelta = _listDelta = _declDelta = YES; \
        _ ## name = name; \
    } \
}

@implementation DSPMutablePropertyAttributes

PropertyWithDeltaFlag(NSString *, backingIvar, BackingIvar);
PropertyWithDeltaFlag(NSString *, typeEncoding, TypeEncoding);
PropertyWithDeltaFlag(NSString *, oldTypeEncoding, OldTypeEncoding);
PropertyWithDeltaFlag(SEL, customGetter, CustomGetter);
PropertyWithDeltaFlag(SEL, customSetter, CustomSetter);
PropertyWithDeltaFlag(BOOL, isReadOnly, IsReadOnly);
PropertyWithDeltaFlag(BOOL, isCopy, IsCopy);
PropertyWithDeltaFlag(BOOL, isRetained, IsRetained);
PropertyWithDeltaFlag(BOOL, isNonatomic, IsNonatomic);
PropertyWithDeltaFlag(BOOL, isDynamic, IsDynamic);
PropertyWithDeltaFlag(BOOL, isWeak, IsWeak);
PropertyWithDeltaFlag(BOOL, isGarbageCollectable, IsGarbageCollectable);

+ (instancetype)attributes {
    return [self new];
}

- (void)setTypeEncodingChar:(char)type {
    self.typeEncoding = [NSString stringWithFormat:@"%c", type];
}

- (NSUInteger)count {
    // Recalculate attribute count after mutations
    if (self.countDelta) {
        self.countDelta = NO;
        _count = self.dictionary.count;
    }

    return _count;
}

- (objc_property_attribute_t *)list {
    // Regenerate list after mutations
    if (self.listDelta) {
        self.listDelta = NO;
        if (_list) {
            free(_list);
            _list = nil;
        }
    }

    // Super will generate the list if it isn't set
    return super.list;
}

- (NSString *)string {
    // Regenerate string after mutations
    if (self.stringDelta || !_string) {
        self.stringDelta = NO;
        _string = self.dictionary.propertyAttributesString;
    }

    return _string;
}

- (NSDictionary *)dictionary {
    // Regenerate dictionary after mutations
    if (self.dictDelta || !_dictionary) {
        // _stringa nd _dictionary depend on each other,
        // so we must generate ONE by hand using our properties.
        // We arbitrarily choose to generate the dictionary.
        NSMutableDictionary *attrs = [NSMutableDictionary new];
        if (self.typeEncoding)
            attrs[kDSPPropertyAttributeKeyTypeEncoding]         = self.typeEncoding;
        if (self.backingIvar)
            attrs[kDSPPropertyAttributeKeyBackingIvarName]      = self.backingIvar;
        if (self.oldTypeEncoding)
            attrs[kDSPPropertyAttributeKeyOldStyleTypeEncoding] = self.oldTypeEncoding;
        if (self.customGetter)
            attrs[kDSPPropertyAttributeKeyCustomGetter]         = NSStringFromSelector(self.customGetter);
        if (self.customSetter)
            attrs[kDSPPropertyAttributeKeyCustomSetter]         = NSStringFromSelector(self.customSetter);

        if (self.isReadOnly)           attrs[kDSPPropertyAttributeKeyReadOnly] = @YES;
        if (self.isCopy)               attrs[kDSPPropertyAttributeKeyCopy] = @YES;
        if (self.isRetained)           attrs[kDSPPropertyAttributeKeyRetain] = @YES;
        if (self.isNonatomic)          attrs[kDSPPropertyAttributeKeyNonAtomic] = @YES;
        if (self.isDynamic)            attrs[kDSPPropertyAttributeKeyDynamic] = @YES;
        if (self.isWeak)               attrs[kDSPPropertyAttributeKeyWeak] = @YES;
        if (self.isGarbageCollectable) attrs[kDSPPropertyAttributeKeyGarbageCollectable] = @YES;

        _dictionary = attrs.copy;
    }

    return _dictionary;
}

- (NSString *)fullDeclaration {
    if (self.declDelta || !_fullDeclaration) {
        _declDelta = NO;
        _fullDeclaration = [self buildFullDeclaration];
    }

    return _fullDeclaration;
}

- (NSString *)customGetterString {
    return _customGetter ? NSStringFromSelector(_customGetter) : nil;
}

- (NSString *)customSetterString {
    return _customSetter ? NSStringFromSelector(_customSetter) : nil;
}

@end
