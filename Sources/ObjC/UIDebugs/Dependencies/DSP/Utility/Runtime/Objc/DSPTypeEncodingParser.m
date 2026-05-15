#import "DSPTypeEncodingParser.h"
#import "DSPRuntimeUtility.h"

#define S(__ch) ({ \
    unichar __c = __ch; \
    [[NSString alloc] initWithCharacters:&__c length:1]; \
})

typedef struct DSPTypeInfo {
    /// The size is unaligned. -1 if not supported at all.
    ssize_t size;
    ssize_t align;
    /// NO if the type cannot be supported at all
    /// YES if the type is either fully or partially supported.
    BOOL supported;
    /// YES if the type was only partially supported, such as in
    /// the case of unions in pointer types, or named structure
    /// types without member info. These can be corrected manually
    /// since they can be fixed or replaced with less info.
    BOOL fixesApplied;
    /// Whether this type is a union or one of its members
    /// recursively contains a union, exlcuding pointers.
    ///
    /// Unions are tricky because they're supported by
    /// \c NSGetSizeAndAlignment but not by \c NSMethodSignature
    /// so we need to track whenever a type contains a union
    /// so that we can clean it out of pointer types.
    BOOL containsUnion;
    /// size can only be 0 if not void
    BOOL isVoid;
} DSPTypeInfo;

/// Type info for a completely unsupported type.
static DSPTypeInfo DSPTypeInfoUnsupported = (DSPTypeInfo){ -1, 0, NO, NO, NO, NO };
/// Type info for the void return type.
static DSPTypeInfo DSPTypeInfoVoid = (DSPTypeInfo){ 0, 0, YES, NO, NO, YES };

/// Builds type info for a fully or partially supported type.
static inline DSPTypeInfo DSPTypeInfoMake(ssize_t size, ssize_t align, BOOL fixed) {
    return (DSPTypeInfo){ size, align, YES, fixed, NO, NO };
}

/// Builds type info for a fully or partially supported type.
static inline DSPTypeInfo DSPTypeInfoMakeU(ssize_t size, ssize_t align, BOOL fixed, BOOL hasUnion) {
    return (DSPTypeInfo){ size, align, YES, fixed, hasUnion, NO };
}

BOOL DSPGetSizeAndAlignment(const char *type, NSUInteger *sizep, NSUInteger *alignp) {
    NSInteger size = 0;
    ssize_t align = 0;
    size = [DSPTypeEncodingParser sizeForTypeEncoding:@(type) alignment:&align];
    
    if (size == -1) {
        return NO;
    }
    
    if (sizep) {
        *sizep = (NSUInteger)size;
    }
    
    if (alignp) {
        *alignp = (NSUInteger)size;
    }
    
    return YES;
}

@interface DSPTypeEncodingParser ()
@property (nonatomic, readonly) NSScanner *scan;
@property (nonatomic, readonly) NSString *scanned;
@property (nonatomic, readonly) NSString *unscanned;
@property (nonatomic, readonly) char nextChar;

/// Replacements are made to this string as we scan as needed
@property (nonatomic) NSMutableString *cleaned;
/// Offset for \e further replacements to be made within \c cleaned
@property (nonatomic, readonly) NSUInteger cleanedReplacingOffset;
@end

@implementation DSPTypeEncodingParser

- (NSString *)scanned {
    return [self.scan.string substringToIndex:self.scan.scanLocation];
}

- (NSString *)unscanned {
    return [self.scan.string substringFromIndex:self.scan.scanLocation];
}

#pragma mark Initialization

- (id)initWithObjCTypes:(NSString *)typeEncoding {
    self = [super init];
    if (self) {
        _scan = [NSScanner scannerWithString:typeEncoding];
        _scan.caseSensitive = YES;
        _cleaned = typeEncoding.mutableCopy;
    }

    return self;
}


#pragma mark Public

+ (BOOL)methodTypeEncodingSupported:(NSString *)typeEncoding cleaned:(NSString * __autoreleasing *)cleanedEncoding {
    if (!typeEncoding.length) {
        return NO;
    }
    
    DSPTypeEncodingParser *parser = [[self alloc] initWithObjCTypes:typeEncoding];
    
    while (!parser.scan.isAtEnd) {
        DSPTypeInfo info = [parser parseNextType];
        
        if (!info.supported || info.containsUnion || (info.size == 0 && !info.isVoid)) {
            return NO;
        }
    }
    
    if (cleanedEncoding) {
        *cleanedEncoding = parser.cleaned.copy;
    }
    
    return YES;
}

+ (NSString *)type:(NSString *)typeEncoding forMethodArgumentAtIndex:(NSUInteger)idx {
    DSPTypeEncodingParser *parser = [[self alloc] initWithObjCTypes:typeEncoding];

    // Scan up to the argument we want
    for (NSUInteger i = 0; i < idx; i++) {
        if (![parser scanPastArg]) {
            [NSException raise:NSRangeException
                format:@"Index %@ out of bounds for type encoding '%@'", 
                @(idx), typeEncoding
            ];
        }
    }

    return [parser scanArg];
}

+ (ssize_t)size:(NSString *)typeEncoding forMethodArgumentAtIndex:(NSUInteger)idx {
    return [self sizeForTypeEncoding:[self type:typeEncoding forMethodArgumentAtIndex:idx] alignment:nil];
}

+ (ssize_t)sizeForTypeEncoding:(NSString *)type alignment:(ssize_t *)alignOut {
    return [self sizeForTypeEncoding:type alignment:alignOut unaligned:NO];
}

+ (ssize_t)sizeForTypeEncoding:(NSString *)type alignment:(ssize_t *)alignOut unaligned:(BOOL)unaligned {
    DSPTypeInfo info = [self parseType:type];
    
    ssize_t size = info.size;
    ssize_t align = info.align;
    
    if (info.supported) {
        if (alignOut) {
            *alignOut = align;
        }

        if (!unaligned) {
            size += size % align;
        }
    }
    
    // size is -1 if not supported
    return size;
}

+ (DSPTypeInfo)parseType:(NSString *)type cleaned:(NSString * __autoreleasing *)cleanedEncoding {
    DSPTypeEncodingParser *parser = [[self alloc] initWithObjCTypes:type];
    DSPTypeInfo info = [parser parseNextType];
    if (cleanedEncoding) {
        *cleanedEncoding = parser.cleaned;
    }
    
    return info;
}

+ (DSPTypeInfo)parseType:(NSString *)type {
    return [self parseType:type cleaned:nil];
}

#pragma mark Private

- (NSCharacterSet *)identifierFirstCharCharacterSet {
    static NSCharacterSet *identifierFirstSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *allowed = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$";
        identifierFirstSet = [NSCharacterSet characterSetWithCharactersInString:allowed];
    });
    
    return identifierFirstSet;
}

- (NSCharacterSet *)identifierCharacterSet {
    static NSCharacterSet *identifierSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *allowed = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$1234567890";
        identifierSet = [NSCharacterSet characterSetWithCharactersInString:allowed];
    });
    
    return identifierSet;
}

- (char)nextChar {
    NSScanner *scan = self.scan;
    return [scan.string characterAtIndex:scan.scanLocation];
}

/// For scanning struct/class names
- (NSString *)scanIdentifier {
    NSString *prefix = nil, *suffix = nil;
    
    // Identifiers cannot start with a number
    if (![self.scan scanCharactersFromSet:self.identifierFirstCharCharacterSet intoString:&prefix]) {
        return nil;
    }
    
    // Optional because identifier may just be one character
    [self.scan scanCharactersFromSet:self.identifierCharacterSet intoString:&suffix];
    
    if (suffix) {
        return [prefix stringByAppendingString:suffix];
    }
    
    return prefix;
}

/// @return the size in bytes
- (ssize_t)sizeForType:(DSPTypeEncoding)type {
    switch (type) {
        case DSPTypeEncodingChar: return sizeof(char);
        case DSPTypeEncodingInt: return sizeof(int);
        case DSPTypeEncodingShort: return sizeof(short);
        case DSPTypeEncodingLong: return sizeof(long);
        case DSPTypeEncodingLongLong: return sizeof(long long);
        case DSPTypeEncodingUnsignedChar: return sizeof(unsigned char);
        case DSPTypeEncodingUnsignedInt: return sizeof(unsigned int);
        case DSPTypeEncodingUnsignedShort: return sizeof(unsigned short);
        case DSPTypeEncodingUnsignedLong: return sizeof(unsigned long);
        case DSPTypeEncodingUnsignedLongLong: return sizeof(unsigned long long);
        case DSPTypeEncodingFloat: return sizeof(float);
        case DSPTypeEncodingDouble: return sizeof(double);
        case DSPTypeEncodingLongDouble: return sizeof(long double);
        case DSPTypeEncodingCBool: return sizeof(_Bool);
        case DSPTypeEncodingVoid: return 0;
        case DSPTypeEncodingCString: return sizeof(char *);
        case DSPTypeEncodingObjcObject:  return sizeof(id);
        case DSPTypeEncodingObjcClass:  return sizeof(Class);
        case DSPTypeEncodingSelector: return sizeof(SEL);
        // Unknown / '?' is typically a pointer. In the rare case
        // it isn't, such as in '{?=...}', it is never passed here.
        case DSPTypeEncodingUnknown:
        case DSPTypeEncodingPointer: return sizeof(uintptr_t);

        default: return -1;
    }
}

- (DSPTypeInfo)parseNextType {
    NSUInteger start = self.scan.scanLocation;

    // Check for void first
    if ([self scanChar:DSPTypeEncodingVoid]) {
        // Skip argument frame for method signatures
        [self scanSize];
        return DSPTypeInfoVoid;
    }

    // Scan optional const
    [self scanChar:DSPTypeEncodingConst];

    // Check for pointer, then scan next
    if ([self scanChar:DSPTypeEncodingPointer]) {
        // Recurse to scan something else
        NSUInteger pointerTypeStart = self.scan.scanLocation;
        if ([self scanPastArg]) {
            // Make sure the pointer type is supported, and clean it if not
            NSUInteger pointerTypeLength = self.scan.scanLocation - pointerTypeStart;
            NSString *pointerType = [self.scan.string
                substringWithRange:NSMakeRange(pointerTypeStart, pointerTypeLength)
            ];
            
            // Deeeep nested cleaning info gets lost here
            NSString *cleaned = nil;
            DSPTypeInfo info = [self.class parseType:pointerType cleaned:&cleaned];
            BOOL needsCleaning = !info.supported || info.containsUnion || info.fixesApplied;
            
            // Clean the type if it is unsupported, malformed, or contains a union.
            // (Unions are supported by NSGetSizeAndAlignment but not
            // supported by NSMethodSignature for some reason)
            if (needsCleaning) {
                // If unsupported, no cleaning occurred in parseType:cleaned: above.
                // Otherwise, the type is partially supported and we did clean it,
                // and we will replace this type with the cleaned type from above.
                if (!info.supported || info.containsUnion) {
                    cleaned = [self cleanPointeeTypeAtLocation:pointerTypeStart];
                }
                
                NSInteger offset = self.cleanedReplacingOffset;
                NSInteger location = pointerTypeStart - offset;
                [self.cleaned replaceCharactersInRange:NSMakeRange(
                    location, pointerTypeLength
                ) withString:cleaned];
            }
            
            // Skip optional frame offset
            [self scanSize];
            
            ssize_t size = [self sizeForType:DSPTypeEncodingPointer];
            return DSPTypeInfoMake(size, size, !info.supported || info.fixesApplied);
        } else {
            // Scan failed, abort
            self.scan.scanLocation = start;
            return DSPTypeInfoUnsupported;
        }
    }

    // Check for struct/union/array
    char next = self.nextChar;
    BOOL didScanSUA = YES, structOrUnion = NO, isUnion = NO;
    DSPTypeEncoding opening = DSPTypeEncodingNull, closing = DSPTypeEncodingNull;
    switch (next) {
        case DSPTypeEncodingStructBegin:
            structOrUnion = YES;
            opening = DSPTypeEncodingStructBegin;
            closing = DSPTypeEncodingStructEnd;
            break;
        case DSPTypeEncodingUnionBegin:
            structOrUnion = isUnion = YES;
            opening = DSPTypeEncodingUnionBegin;
            closing = DSPTypeEncodingUnionEnd;
            break;
        case DSPTypeEncodingArrayBegin:
            opening = DSPTypeEncodingArrayBegin;
            closing = DSPTypeEncodingArrayEnd;
            break;
            
        default:
            didScanSUA = NO;
            break;
    }
    
    if (didScanSUA) {
        BOOL containsUnion = isUnion;
        BOOL fixesApplied = NO;
        
        NSUInteger backup = self.scan.scanLocation;

        // Ensure we have a closing tag
        if (![self scanPair:opening close:closing]) {
            // Scan failed, abort
            self.scan.scanLocation = start;
            return DSPTypeInfoUnsupported;
        }

        // Move cursor just after opening tag (struct/union/array)
        NSInteger arrayCount = -1;
        self.scan.scanLocation = backup + 1;
        
        if (!structOrUnion) {
            arrayCount = [self scanSize];
            if (!arrayCount || self.nextChar == DSPTypeEncodingArrayEnd) {
                // Malformed array type:
                // 1. Arrays must have a count after the opening brace
                // 2. Arrays must have an element type after the count
                self.scan.scanLocation = start;
                return DSPTypeInfoUnsupported;
            }
        } else {
            // If we encounter the ?= portion of something like {?=b8b4b1b1b18[8S]}
            // then we skip over it, since it means nothing to us in this context.
            // It is completely optional, and if it fails, we go right back where we were.
            if (![self scanTypeName] && self.nextChar == DSPTypeEncodingUnknown) {
                // Exception: we are trying to parse {?} which is invalid
                self.scan.scanLocation = start;
                return DSPTypeInfoUnsupported;
            }
        }

        // Sum sizes of members together:
        // Scan for bitfields before checking for other members
        //
        // Arrays will only have one "member," but
        // this logic still works for them
        ssize_t sizeSoFar = 0;
        ssize_t maxAlign = 0;
        NSMutableString *cleanedBackup = self.cleaned.mutableCopy;
        
        while (![self scanChar:closing]) {
            next = self.nextChar;
            // Check for bitfields, which we cannot support because
            // type encodings for bitfields do not include alignment info
            if (next == DSPTypeEncodingBitField) {
                self.scan.scanLocation = start;
                return DSPTypeInfoUnsupported;
            }

            // Structure fields could be named
            if (next == DSPTypeEncodingQuote) {
                [self scanPair:DSPTypeEncodingQuote close:DSPTypeEncodingQuote];
            }

            DSPTypeInfo info = [self parseNextType];
            if (!info.supported || info.containsUnion) {
                // The above call is the only time in this method where
                // `cleaned` might be mutated recursively, so this is the
                // only place where we need to keep and restore a backup
                //
                // For instance, if we've been iterating over the members
                // of a struct and we've encountered a few pointers so far
                // that we needed to clean, and suddenly we come across an
                // unsupported member, we need to be able to "rewind" and
                // undo any changes to `self.cleaned` so that the parent
                // call in the call stack can wipe the current structure
                // clean entirely if needed. Example below:
                //
                //      Initial: ^{foo=^{pair<d,d>}{^pair<i,i>}{invalid_type<d>}}
                //                       v-- here
                //    1st clean: ^{foo=^{?=}{^pair<i,i>}{invalid_type<d>}
                //                           v-- here
                //    2nd clean: ^{foo=^{?=}{?=}{invalid_type<d>}
                //                               v-- here
                //  Can't clean: ^{foo=^{?=}{?=}{invalid_type<d>}
                //                 v-- to here
                //       Rewind: ^{foo=^{pair<d,d>}{^pair<i,i>}{invalid_type<d>}}
                //  Final clean: ^{foo=}
                self.cleaned = cleanedBackup;
                self.scan.scanLocation = start;
                return DSPTypeInfoUnsupported;
            }
            
            // Unions are the size of their largest member,
            // arrays are element.size x length, and
            // structs are the sum of their members
            if (structOrUnion) {
                if (isUnion) { // Union
                    sizeSoFar = MAX(sizeSoFar, info.size);
                } else { // Struct
                    sizeSoFar += info.size;
                }
            } else { // Array
                sizeSoFar = info.size * arrayCount;
            }
            
            // Propogate the max alignment and other metadata
            maxAlign = MAX(maxAlign, info.align);
            containsUnion = containsUnion || info.containsUnion;
            fixesApplied = fixesApplied || info.fixesApplied;
        }
        
        // Skip optional frame offset
        [self scanSize];

        return DSPTypeInfoMakeU(sizeSoFar, maxAlign, fixesApplied, containsUnion);
    }
    
    // Scan single thing and possible size and return
    ssize_t size = -1;
    char t = self.nextChar;
    switch (t) {
        case DSPTypeEncodingUnknown:
        case DSPTypeEncodingChar:
        case DSPTypeEncodingInt:
        case DSPTypeEncodingShort:
        case DSPTypeEncodingLong:
        case DSPTypeEncodingLongLong:
        case DSPTypeEncodingUnsignedChar:
        case DSPTypeEncodingUnsignedInt:
        case DSPTypeEncodingUnsignedShort:
        case DSPTypeEncodingUnsignedLong:
        case DSPTypeEncodingUnsignedLongLong:
        case DSPTypeEncodingFloat:
        case DSPTypeEncodingDouble:
        case DSPTypeEncodingLongDouble:
        case DSPTypeEncodingCBool:
        case DSPTypeEncodingCString:
        case DSPTypeEncodingSelector:
        case DSPTypeEncodingBitField: {
            self.scan.scanLocation++;
            // Skip optional frame offset
            [self scanSize];
            
            if (t == DSPTypeEncodingBitField) {
                self.scan.scanLocation = start;
                return DSPTypeInfoUnsupported;
            } else {
                // Compute size
                size = [self sizeForType:t];
            }
        }
            break;
        
        case DSPTypeEncodingObjcObject:
        case DSPTypeEncodingObjcClass: {
            self.scan.scanLocation++;
            // These might have numbers OR quotes after them
            // Skip optional frame offset
            [self scanSize];
            [self scanPair:DSPTypeEncodingQuote close:DSPTypeEncodingQuote];
            size = sizeof(id);
        }
            break;
            
        default: break;
    }

    if (size > 0) {
        // Alignment of scalar types is its size
        return DSPTypeInfoMake(size, size, NO);
    }

    self.scan.scanLocation = start;
    return DSPTypeInfoUnsupported;
}

- (BOOL)scanString:(NSString *)str {
    return [self.scan scanString:str intoString:nil];
}

- (BOOL)canScanString:(NSString *)str {
    NSScanner *scan = self.scan;
    NSUInteger len = str.length;
    unichar buff1[len], buff2[len];
    
    [str getCharacters:buff1];
    [scan.string getCharacters:buff2 range:NSMakeRange(scan.scanLocation, len)];
    if (memcmp(buff1, buff2, len) == 0) {
        return YES;
    }

    return NO;
}

- (BOOL)canScanChar:(char)c {
    // By avoiding any ARC calls on these two objects which we know won't be
    // free'd out from under us, we're making HUGE performance savings in this
    // parser, because this method is one of the most-used methods of the parser.
    // This is probably the most performance-critical method in this class.
    __unsafe_unretained NSScanner *scan = self.scan;
    __unsafe_unretained NSString *string = scan.string;
    if (scan.scanLocation >= string.length) return NO;
    
    return [string characterAtIndex:scan.scanLocation] == c;
}

- (BOOL)scanChar:(char)c {
    if ([self canScanChar:c]) {
        self.scan.scanLocation++;
        return YES;
    }
    
    return NO;
}

- (BOOL)scanChar:(char)c into:(char *)ref {
    if ([self scanChar:c]) {
        *ref = c;
        return YES;
    }

    return NO;
}

- (ssize_t)scanSize {
    NSInteger size = 0;
    if ([self.scan scanInteger:&size]) {
        return size;
    }

    return 0;
}

- (NSString *)scanPair:(char)c1 close:(char)c2 {
    // Starting position and string variables
    NSUInteger start = self.scan.scanLocation;
    NSString *s1 = S(c1);

    // Scan opening tag
    if (![self scanChar:c1]) {
        self.scan.scanLocation = start;
        return nil;
    }

    // Character set for scanning up to either symbol
    NSCharacterSet *bothChars = ({
        unichar buff[2] = { c1, c2 };
        NSString *bothCharsStr = [[NSString alloc] initWithCharacters:buff length:2];
        [NSCharacterSet characterSetWithCharactersInString:bothCharsStr];
    });

    // Stack for finding pairs, starting with the opening symbol
    NSMutableArray *stack = [NSMutableArray arrayWithObject:s1];

    // Algorithm for scanning to the closing end of a pair of opening/closing symbols
    // scanUpToCharactersFromSet:intoString: returns NO if you're already at one of the chars,
    // so we need to check if we can actually scan one if it returns NO
    while ([self.scan scanUpToCharactersFromSet:bothChars intoString:nil] ||
           [self canScanChar:c1] || [self canScanChar:c2]) {
        // Closing symbol found
        if ([self scanChar:c2]) {
            if (!stack.count) {
                // Abort, no matching opening symbol
                self.scan.scanLocation = start;
                return nil;
            }

            // Pair found, pop opening symbol
            [stack removeLastObject];
            // Exit loop if we reached the closing brace we needed
            if (!stack.count) {
                break;
            }
        }
        // Opening symbol found
        if ([self scanChar:c1]) {
            // Begin pair
            [stack addObject:s1];
        }
    }

    if (stack.count) {
        // Abort, no matching closing symbol
        self.scan.scanLocation = start;
        return nil;
    }

    // Slice out the string we just scanned
    return [self.scan.string
        substringWithRange:NSMakeRange(start, self.scan.scanLocation - start)
    ];
}

- (BOOL)scanPastArg {
    NSUInteger start = self.scan.scanLocation;

    // Check for void first
    if ([self scanChar:DSPTypeEncodingVoid]) {
        return YES;
    }

    // Scan optional const
    [self scanChar:DSPTypeEncodingConst];

    // Check for pointer, then scan next
    if ([self scanChar:DSPTypeEncodingPointer]) {
        // Recurse to scan something else
        if ([self scanPastArg]) {
            return YES;
        } else {
            // Scan failed, abort
            self.scan.scanLocation = start;
            return NO;
        }
    }
    
    char next = self.nextChar;

    // Check for struct/union/array, scan past it
    DSPTypeEncoding opening = DSPTypeEncodingNull, closing = DSPTypeEncodingNull;
    BOOL checkPair = YES;
    switch (next) {
        case DSPTypeEncodingStructBegin:
            opening = DSPTypeEncodingStructBegin;
            closing = DSPTypeEncodingStructEnd;
            break;
        case DSPTypeEncodingUnionBegin:
            opening = DSPTypeEncodingUnionBegin;
            closing = DSPTypeEncodingUnionEnd;
            break;
        case DSPTypeEncodingArrayBegin:
            opening = DSPTypeEncodingArrayBegin;
            closing = DSPTypeEncodingArrayEnd;
            break;
            
        default:
            checkPair = NO;
            break;
    }
    
    if (checkPair && [self scanPair:opening close:closing]) {
        return YES;
    }

    // Scan single thing and possible size and return
    switch (next) {
        case DSPTypeEncodingUnknown:
        case DSPTypeEncodingChar:
        case DSPTypeEncodingInt:
        case DSPTypeEncodingShort:
        case DSPTypeEncodingLong:
        case DSPTypeEncodingLongLong:
        case DSPTypeEncodingUnsignedChar:
        case DSPTypeEncodingUnsignedInt:
        case DSPTypeEncodingUnsignedShort:
        case DSPTypeEncodingUnsignedLong:
        case DSPTypeEncodingUnsignedLongLong:
        case DSPTypeEncodingFloat:
        case DSPTypeEncodingDouble:
        case DSPTypeEncodingLongDouble:
        case DSPTypeEncodingCBool:
        case DSPTypeEncodingCString:
        case DSPTypeEncodingSelector:
        case DSPTypeEncodingBitField: {
            self.scan.scanLocation++;
            // Size is optional
            [self scanSize];
            return YES;
        }
        
        case DSPTypeEncodingObjcObject:
        case DSPTypeEncodingObjcClass: {
            self.scan.scanLocation++;
            // These might have numbers OR quotes after them
            [self scanSize] || [self scanPair:DSPTypeEncodingQuote close:DSPTypeEncodingQuote];
            return YES;
        }
            
        default: break;
    }

    self.scan.scanLocation = start;
    return NO;
}

- (NSString *)scanArg {
    NSUInteger start = self.scan.scanLocation;
    if (![self scanPastArg]) {
        return nil;
    }

    return [self.scan.string
        substringWithRange:NSMakeRange(start, self.scan.scanLocation - start)
    ];
}

- (BOOL)scanTypeName {
    NSUInteger start = self.scan.scanLocation;

    // The ?= portion of something like {?=b8b4b1b1b18[8S]}
    if ([self scanChar:DSPTypeEncodingUnknown]) {
        if (![self scanString:@"="]) {
            // No size information available for strings like {?=}
            self.scan.scanLocation = start;
            return NO;
        }
    } else {
        if (![self scanIdentifier] || ![self scanString:@"="]) {
            // 1. Not a valid identifier
            // 2. No size information available for strings like {CGPoint}
            self.scan.scanLocation = start;
            return NO;
        }
    }

    return YES;
}

- (NSString *)extractTypeNameFromScanLocation:(BOOL)allowMissingTypeInfo closing:(DSPTypeEncoding)closeTag {
    NSUInteger start = self.scan.scanLocation;

    // The ?= portion of something like {?=b8b4b1b1b18[8S]}
    if ([self scanChar:DSPTypeEncodingUnknown]) {
        return @"?";
    } else {
        NSString *typeName = [self scanIdentifier];
        char next = self.nextChar;
        
        if (!typeName) {
            // Did not scan an identifier
            self.scan.scanLocation = start;
            return nil;
        }
        
        switch (next) {
            case '=':
                return typeName;
                
            default: {
                // = is non-optional unless we allowMissingTypeInfo, in whcih
                // case the next character needs to be a closing brace
                if (allowMissingTypeInfo && next == closeTag) {
                    return typeName;
                } else {
                    // Not a valid identifier; possibly a generic C++ type
                    // i.e. {pair<T, U>} where `name` was found as `pair`
                    self.scan.scanLocation = start;
                    return nil;
                }
            }
        }
    }
}

- (NSString *)cleanPointeeTypeAtLocation:(NSUInteger)scanLocation {
    NSUInteger start = self.scan.scanLocation;
    self.scan.scanLocation = scanLocation;
    
    // The return / cleanup code for when the scanned type is already clean
    NSString * (^typeIsClean)(void) = ^NSString * {
        NSString *clean = [self.scan.string
            substringWithRange:NSMakeRange(scanLocation, self.scan.scanLocation - scanLocation)
        ];
        // Reset scan location even on success, because this method is not supposed to change it
        self.scan.scanLocation = start;
        return clean;
    };

    // No void, this is not a return type

    // Scan optional const
    [self scanChar:DSPTypeEncodingConst];
    
    char next = self.nextChar;
    switch (next) {
        case DSPTypeEncodingPointer:
            // Recurse to scan something else
            [self scanChar:next];
            return [self cleanPointeeTypeAtLocation:self.scan.scanLocation];
            
        case DSPTypeEncodingArrayBegin:
            // All arrays are supported, scan past them
            if ([self scanPair:DSPTypeEncodingArrayBegin close:DSPTypeEncodingArrayEnd]) {
                return typeIsClean();
            }
            break;
            
        case DSPTypeEncodingUnionBegin:
            // Unions are not supported at all in NSMethodSignature
            // We could check for the closing token to be safe, but eh
            self.scan.scanLocation = start;
            return @"?";
            
        case DSPTypeEncodingStructBegin: {
            DSPTypeInfo info = [self.class parseType:self.unscanned];
            if (info.supported && !info.fixesApplied) {
                [self scanPastArg];
                return typeIsClean();
            }
            
            // The structure we just tried to scan is unsupported, so just return its name
            // if it has one. If not, just return a question mark.
            self.scan.scanLocation++; // Skip past {
            NSString *name = [self extractTypeNameFromScanLocation:YES closing:DSPTypeEncodingStructEnd];
            if (name) {
                // Got the name, scan past the closing token
                [self.scan scanUpToString:@"}" intoString:nil];
                if (![self scanChar:DSPTypeEncodingStructEnd]) {
                    // Missing struct close token
                    self.scan.scanLocation = start;
                    return nil;
                }
            } else {
                // Did not scan valid identifier, possibly a C++ type
                self.scan.scanLocation = start;
                return @"{?=}";
            }
            
            // Reset scan location even on success, because this method is not supposed to change it
            self.scan.scanLocation = start;
            return ({ // "{name=}"
                NSMutableString *format = @"{".mutableCopy;
                [format appendString:name];
                [format appendString:@"=}"];
                format;
            });
        }
        
        default:
            break;
    }
    
    // Check for other types, which in theory are all valid but whatever
    DSPTypeInfo info = [self parseNextType];
    if (info.supported && !info.fixesApplied) {
        return typeIsClean();
    }
    
    self.scan.scanLocation = start;
    return @"?";
}

- (NSUInteger)cleanedReplacingOffset {
    return self.scan.string.length - self.cleaned.length;
}

@end
