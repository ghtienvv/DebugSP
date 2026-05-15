#import "DSPRuntimeKeyPathTokenizer.h"

#define TBCountOfStringOccurence(target, str) ([target componentsSeparatedByString:str].count - 1)

@implementation DSPRuntimeKeyPathTokenizer

#pragma mark Initialization

static NSCharacterSet *firstAllowed      = nil;
static NSCharacterSet *identifierAllowed = nil;
static NSCharacterSet *filenameAllowed   = nil;
static NSCharacterSet *keyPathDisallowed = nil;
static NSCharacterSet *methodAllowed     = nil;
+ (void)initialize {
    if (self == [self class]) {
        NSString *_methodFirstAllowed    = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_$";
        NSString *_identifierAllowed     = [_methodFirstAllowed stringByAppendingString:@"1234567890"];
        NSString *_methodAllowedSansType = [_identifierAllowed stringByAppendingString:@":"];
        NSString *_filenameNameAllowed   = [_identifierAllowed stringByAppendingString:@"-+?!"];
        firstAllowed      = [NSCharacterSet characterSetWithCharactersInString:_methodFirstAllowed];
        identifierAllowed = [NSCharacterSet characterSetWithCharactersInString:_identifierAllowed];
        filenameAllowed   = [NSCharacterSet characterSetWithCharactersInString:_filenameNameAllowed];
        methodAllowed     = [NSCharacterSet characterSetWithCharactersInString:_methodAllowedSansType];

        NSString *_kpDisallowed = [_identifierAllowed stringByAppendingString:@"-+:\\.*"];
        keyPathDisallowed = [NSCharacterSet characterSetWithCharactersInString:_kpDisallowed].invertedSet;
    }
}

#pragma mark Public

+ (DSPRuntimeKeyPath *)tokenizeString:(NSString *)userInput {
    if (!userInput.length) {
        return nil;
    }

    NSUInteger tokens = [self tokenCountOfString:userInput];
    if (tokens == 0) {
        return nil;
    }

    if ([userInput containsString:@"**"]) {
        @throw NSInternalInconsistencyException;
    }

    NSNumber *instance = nil;
    NSScanner *scanner = [NSScanner scannerWithString:userInput];
    DSPSearchToken *bundle    = [self scanToken:scanner allowed:filenameAllowed first:filenameAllowed];
    DSPSearchToken *cls       = [self scanToken:scanner allowed:identifierAllowed first:firstAllowed];
    DSPSearchToken *method    = tokens > 2 ? [self scanMethodToken:scanner instance:&instance] : nil;

    return [DSPRuntimeKeyPath bundle:bundle
                       class:cls
                      method:method
                  isInstance:instance
                      string:userInput];
}

+ (BOOL)allowedInKeyPath:(NSString *)text {
    if (!text.length) {
        return YES;
    }
    
    return [text rangeOfCharacterFromSet:keyPathDisallowed].location == NSNotFound;
}

#pragma mark Private

+ (NSUInteger)tokenCountOfString:(NSString *)userInput {
    NSUInteger escapedCount = TBCountOfStringOccurence(userInput, @"\\.");
    NSUInteger tokenCount  = TBCountOfStringOccurence(userInput, @".") - escapedCount + 1;

    return tokenCount;
}

+ (DSPSearchToken *)scanToken:(NSScanner *)scanner allowed:(NSCharacterSet *)allowedChars first:(NSCharacterSet *)first {
    if (scanner.isAtEnd) {
        if ([scanner.string hasSuffix:@"."] && ![scanner.string hasSuffix:@"\\."]) {
            return [DSPSearchToken string:nil options:TBWildcardOptionsAny];
        }
        return nil;
    }

    TBWildcardOptions options = TBWildcardOptionsNone;
    NSMutableString *token = [NSMutableString new];

    // Token cannot start with '.'
    if ([scanner scanString:@"." intoString:nil]) {
        @throw NSInternalInconsistencyException;
    }

    if ([scanner scanString:@"*." intoString:nil]) {
        return [DSPSearchToken string:nil options:TBWildcardOptionsAny];
    } else if ([scanner scanString:@"*" intoString:nil]) {
        if (scanner.isAtEnd) {
            return DSPSearchToken.any;
        }
        
        options |= TBWildcardOptionsPrefix;
    }

    NSString *tmp = nil;
    BOOL stop = NO, didScanDelimiter = NO, didScanFirstAllowed = NO;
    NSCharacterSet *disallowed = allowedChars.invertedSet;
    while (!stop && ![scanner scanString:@"." intoString:&tmp] && !scanner.isAtEnd) {
        // Scan word chars
        // In this block, we have not scanned anything yet, except maybe leading '\' or '\.'
        if (!didScanFirstAllowed) {
            if ([scanner scanCharactersFromSet:first intoString:&tmp]) {
                [token appendString:tmp];
                didScanFirstAllowed = YES;
            } else if ([scanner scanString:@"\\" intoString:nil]) {
                if (options == TBWildcardOptionsPrefix && [scanner scanString:@"." intoString:nil]) {
                    [token appendString:@"."];
                } else if (scanner.isAtEnd && options == TBWildcardOptionsPrefix) {
                    // Only allow standalone '\' if prefixed by '*'
                    return DSPSearchToken.any;
                } else {
                    // Token starts with a number, period, or something else not allowed,
                    // or token is a standalone '\' with no '*' prefix
                    @throw NSInternalInconsistencyException;
                }
            } else {
                // Token starts with a number, period, or something else not allowed
                @throw NSInternalInconsistencyException;
            }
        } else if ([scanner scanCharactersFromSet:allowedChars intoString:&tmp]) {
            [token appendString:tmp];
        }
        // Scan '\.' or trailing '\'
        else if ([scanner scanString:@"\\" intoString:nil]) {
            if ([scanner scanString:@"." intoString:nil]) {
                [token appendString:@"."];
            } else if (scanner.isAtEnd) {
                // Ignore forward slash not followed by period if at end
                return [DSPSearchToken string:token options:options | TBWildcardOptionsSuffix];
            } else {
                // Only periods can follow a forward slash
                @throw NSInternalInconsistencyException;
            }
        }
        // Scan '*.'
        else if ([scanner scanString:@"*." intoString:nil]) {
            options |= TBWildcardOptionsSuffix;
            stop = YES;
            didScanDelimiter = YES;
        }
        // Scan '*' not followed by .
        else if ([scanner scanString:@"*" intoString:nil]) {
            if (!scanner.isAtEnd) {
                // Invalid token, wildcard in middle of token
                @throw NSInternalInconsistencyException;
            }
        } else if ([scanner scanCharactersFromSet:disallowed intoString:nil]) {
            // Invalid token, invalid characters
            @throw NSInternalInconsistencyException;
        }
    }

    // Did we scan a trailing, un-escsaped '.'?
    if ([tmp isEqualToString:@"."]) {
        didScanDelimiter = YES;
    }

    if (!didScanDelimiter) {
        options |= TBWildcardOptionsSuffix;
    }

    return [DSPSearchToken string:token options:options];
}

+ (DSPSearchToken *)scanMethodToken:(NSScanner *)scanner instance:(NSNumber **)instance {
    if (scanner.isAtEnd) {
        if ([scanner.string hasSuffix:@"."]) {
            return [DSPSearchToken string:nil options:TBWildcardOptionsAny];
        }
        return nil;
    }

    if ([scanner.string hasSuffix:@"."] && ![scanner.string hasSuffix:@"\\."]) {
        // Methods cannot end with '.' except for '\.'
        @throw NSInternalInconsistencyException;
    }
    
    if ([scanner scanString:@"-" intoString:nil]) {
        *instance = @YES;
    } else if ([scanner scanString:@"+" intoString:nil]) {
        *instance = @NO;
    } else {
        if ([scanner scanString:@"*" intoString:nil]) {
            // Just checking... It has to start with one of these three!
            scanner.scanLocation--;
        } else {
            @throw NSInternalInconsistencyException;
        }
    }

    // -*foo not allowed
    if (*instance && [scanner scanString:@"*" intoString:nil]) {
        @throw NSInternalInconsistencyException;
    }

    if (scanner.isAtEnd) {
        return [DSPSearchToken string:@"" options:TBWildcardOptionsSuffix];
    }

    return [self scanToken:scanner allowed:methodAllowed first:firstAllowed];
}

@end
