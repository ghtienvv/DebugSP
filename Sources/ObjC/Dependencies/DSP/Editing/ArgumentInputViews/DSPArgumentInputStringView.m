#import "DSPArgumentInputStringView.h"
#import "DSPRuntimeUtility.h"

@implementation DSPArgumentInputStringView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        DSPTypeEncoding type = typeEncoding[0];
        if (type == DSPTypeEncodingConst) {
            // A crash here would mean an invalid type encoding string
            type = typeEncoding[1];
        }

        // Selectors don't need a multi-line text box
        if (type == DSPTypeEncodingSelector) {
            self.targetSize = DSPArgumentInputViewSizeSmall;
        } else {
            self.targetSize = DSPArgumentInputViewSizeLarge;
        }
    }
    return self;
}

- (void)setInputValue:(id)inputValue {
    if ([inputValue isKindOfClass:[NSString class]]) {
        self.inputTextView.text = inputValue;
    } else if ([inputValue isKindOfClass:[NSValue class]]) {
        NSValue *value = (id)inputValue;
        NSParameterAssert(strlen(value.objCType) == 1);

        // C-String or SEL from NSValue
        DSPTypeEncoding type = value.objCType[0];
        if (type == DSPTypeEncodingConst) {
            // A crash here would mean an invalid type encoding string
            type = value.objCType[1];
        }

        if (type == DSPTypeEncodingCString) {
            self.inputTextView.text = @((const char *)value.pointerValue);
        } else if (type == DSPTypeEncodingSelector) {
            self.inputTextView.text = NSStringFromSelector((SEL)value.pointerValue);
        }
    }
}

- (id)inputValue {
    NSString *text = self.inputTextView.text;
    // Interpret empty string as nil. We loose the ability to set empty string as a string value,
    // but we accept that tradeoff in exchange for not having to type quotes for every string.
    if (!text.length) {
        return nil;
    }

    // Case: C-strings and SELs
    if (self.typeEncoding.length <= 2) {
        DSPTypeEncoding type = [self.typeEncoding characterAtIndex:0];
        if (type == DSPTypeEncodingConst) {
            // A crash here would mean an invalid type encoding string
            type = [self.typeEncoding characterAtIndex:1];
        }

        if (type == DSPTypeEncodingCString || type == DSPTypeEncodingSelector) {
            const char *encoding = self.typeEncoding.UTF8String;
            SEL selector = NSSelectorFromString(text);
            return [NSValue valueWithBytes:&selector objCType:encoding];
        }
    }

    // Case: NSStrings
    return self.inputTextView.text.copy;
}

// TODO: Support using object address for strings, as in the object arg view.

+ (BOOL)supportsObjCType:(const char *)type withCurrentValue:(id)value {
    NSParameterAssert(type);
    unsigned long len = strlen(type);

    BOOL isConst = type[0] == DSPTypeEncodingConst;
    NSInteger i = isConst ? 1 : 0;

    BOOL typeIsString = strcmp(type, DSPEncodeClass(NSString)) == 0;
    BOOL typeIsCString = len <= 2 && type[i] == DSPTypeEncodingCString;
    BOOL typeIsSEL = len <= 2 && type[i] == DSPTypeEncodingSelector;
    BOOL valueIsString = [value isKindOfClass:[NSString class]];

    BOOL typeIsPrimitiveString = typeIsSEL || typeIsCString;
    BOOL typeIsSupported = typeIsString || typeIsCString || typeIsSEL;

    BOOL valueIsNSValueWithCorrectType = NO;
    if ([value isKindOfClass:[NSValue class]]) {
        NSValue *v = (id)value;
        len = strlen(v.objCType);
        if (len == 1) {
            DSPTypeEncoding type = v.objCType[i];
            if (type == DSPTypeEncodingCString && typeIsCString) {
                valueIsNSValueWithCorrectType = YES;
            } else if (type == DSPTypeEncodingSelector && typeIsSEL) {
                valueIsNSValueWithCorrectType = YES;
            }
        }
    }

    if (!value && typeIsSupported) {
        return YES;
    }

    if (typeIsString && valueIsString) {
        return YES;
    }

    // Primitive strings can be input as NSStrings or NSValues
    if (typeIsPrimitiveString && (valueIsString || valueIsNSValueWithCorrectType)) {
        return YES;
    }

    return NO;
}

@end
