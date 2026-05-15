#import "DSPArgumentInputNumberView.h"
#import "DSPRuntimeUtility.h"

@implementation DSPArgumentInputNumberView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        self.inputTextView.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
        self.targetSize = DSPArgumentInputViewSizeSmall;
    }
    
    return self;
}

- (void)setInputValue:(id)inputValue {
    if ([inputValue respondsToSelector:@selector(stringValue)]) {
        self.inputTextView.text = [inputValue stringValue];
    }
}

- (id)inputValue {
    return [DSPRuntimeUtility valueForNumberWithObjCType:self.typeEncoding.UTF8String fromInputString:self.inputTextView.text];
}

+ (BOOL)supportsObjCType:(const char *)type withCurrentValue:(id)value {
    NSParameterAssert(type);
    
    static NSArray<NSString *> *supportedTypes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        supportedTypes = @[
            @DSPEncodeClass(NSNumber),
            @DSPEncodeClass(NSDecimalNumber),
            @(@encode(char)),
            @(@encode(int)),
            @(@encode(short)),
            @(@encode(long)),
            @(@encode(long long)),
            @(@encode(unsigned char)),
            @(@encode(unsigned int)),
            @(@encode(unsigned short)),
            @(@encode(unsigned long)),
            @(@encode(unsigned long long)),
            @(@encode(float)),
            @(@encode(double)),
            @(@encode(long double))
        ];
    });
    
    return type && [supportedTypes containsObject:@(type)];
}

@end
