#import "NSString+DSP.h"

@interface NSMutableString (Replacement)
- (void)replaceOccurencesOfString:(NSString *)string with:(NSString *)replacement;
- (void)removeLastKeyPathComponent;
@end

@implementation NSMutableString (Replacement)

- (void)replaceOccurencesOfString:(NSString *)string with:(NSString *)replacement {
    [self replaceOccurrencesOfString:string withString:replacement options:0 range:NSMakeRange(0, self.length)];
}

- (void)removeLastKeyPathComponent {
    if (![self containsString:@"."]) {
        [self deleteCharactersInRange:NSMakeRange(0, self.length)];
        return;
    }

    BOOL putEscapesBack = NO;
    if ([self containsString:@"\\."]) {
        [self replaceOccurencesOfString:@"\\." with:@"\\~"];

        // Case like "UIKit\.framework"
        if (![self containsString:@"."]) {
            [self deleteCharactersInRange:NSMakeRange(0, self.length)];
            return;
        }

        putEscapesBack = YES;
    }

    // Case like "Bund" or "Bundle.cla"
    if (![self hasSuffix:@"."]) {
        NSUInteger len = self.pathExtension.length;
        [self deleteCharactersInRange:NSMakeRange(self.length-len, len)];
    }

    if (putEscapesBack) {
        [self replaceOccurencesOfString:@"\\~" with:@"\\."];
    }
}

@end

@implementation NSString (DSPTypeEncoding)

- (NSCharacterSet *)dsp_classNameAllowedCharactersSet {
    static NSCharacterSet *classNameAllowedCharactersSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *temp = NSMutableCharacterSet.alphanumericCharacterSet;
        [temp addCharactersInString:@"_"];
        classNameAllowedCharactersSet = temp.copy;
    });
    
    return classNameAllowedCharactersSet;
}

- (BOOL)dsp_typeIsConst {
    if (!self.length) return NO;
    return [self characterAtIndex:0] == DSPTypeEncodingConst;
}

- (DSPTypeEncoding)dsp_firstNonConstType {
    if (!self.length) return DSPTypeEncodingNull;
    return [self characterAtIndex:(self.dsp_typeIsConst ? 1 : 0)];
}

- (DSPTypeEncoding)dsp_pointeeType {
    if (!self.length) return DSPTypeEncodingNull;
    
    if (self.dsp_firstNonConstType == DSPTypeEncodingPointer) {
        return [self characterAtIndex:(self.dsp_typeIsConst ? 2 : 1)];
    }
    
    return DSPTypeEncodingNull;
}

- (BOOL)dsp_typeIsObjectOrClass {
    DSPTypeEncoding type = self.dsp_firstNonConstType;
    return type == DSPTypeEncodingObjcObject || type == DSPTypeEncodingObjcClass;
}

- (Class)dsp_typeClass {
    if (!self.dsp_typeIsObjectOrClass) {
        return nil;
    }
    
    NSScanner *scan = [NSScanner scannerWithString:self];
    // Skip const
    [scan scanString:@"r" intoString:nil];
    // Scan leading @"
    if (![scan scanString:@"@\"" intoString:nil]) {
        return nil;
    }
    
    // Scan class name
    NSString *name = nil;
    if (![scan scanCharactersFromSet:self.dsp_classNameAllowedCharactersSet intoString:&name]) {
        return nil;
    }
    // Scan trailing quote
    if (![scan scanString:@"\"" intoString:nil]) {
        return nil;
    }
    
    // Return found class
    return NSClassFromString(name);
}

- (BOOL)dsp_typeIsNonObjcPointer {
    DSPTypeEncoding type = self.dsp_firstNonConstType;
    return type == DSPTypeEncodingPointer ||
           type == DSPTypeEncodingCString ||
           type == DSPTypeEncodingSelector;
}

@end

@implementation NSString (KeyPaths)

- (NSString *)dsp_stringByRemovingLastKeyPathComponent {
    if (![self containsString:@"."]) {
        return @"";
    }

    NSMutableString *mself = self.mutableCopy;
    [mself removeLastKeyPathComponent];
    return mself;
}

- (NSString *)dsp_stringByReplacingLastKeyPathComponent:(NSString *)replacement {
    // replacement should not have any escaped '.' in it,
    // so we escape all '.'
    if ([replacement containsString:@"."]) {
        replacement = [replacement stringByReplacingOccurrencesOfString:@"." withString:@"\\."];
    }

    // Case like "Foo"
    if (![self containsString:@"."]) {
        return [replacement stringByAppendingString:@"."];
    }

    NSMutableString *mself = self.mutableCopy;
    [mself removeLastKeyPathComponent];
    [mself appendString:replacement];
    [mself appendString:@"."];
    return mself;
}

@end
