#import "DSPArgumentInputViewFactory.h"
#import "DSPArgumentInputView.h"
#import "DSPArgumentInputObjectView.h"
#import "DSPArgumentInputNumberView.h"
#import "DSPArgumentInputSwitchView.h"
#import "DSPArgumentInputStructView.h"
#import "DSPArgumentInputNotSupportedView.h"
#import "DSPArgumentInputStringView.h"
#import "DSPArgumentInputFontView.h"
#import "DSPArgumentInputColorView.h"
#import "DSPArgumentInputDateView.h"
#import "DSPRuntimeUtility.h"

@implementation DSPArgumentInputViewFactory

+ (DSPArgumentInputView *)argumentInputViewForTypeEncoding:(const char *)typeEncoding {
    return [self argumentInputViewForTypeEncoding:typeEncoding currentValue:nil];
}

+ (DSPArgumentInputView *)argumentInputViewForTypeEncoding:(const char *)typeEncoding currentValue:(id)currentValue {
    Class subclass = [self argumentInputViewSubclassForTypeEncoding:typeEncoding currentValue:currentValue];
    if (!subclass) {
        // Fall back to a DSPArgumentInputNotSupportedView if we can't find a subclass that fits the type encoding.
        // The unsupported view shows "nil" and does not allow user input.
        subclass = [DSPArgumentInputNotSupportedView class];
    }
    // Remove the field name if there is any (e.g. \"width\"d -> d)
    const NSUInteger fieldNameOffset = [DSPRuntimeUtility fieldNameOffsetForTypeEncoding:typeEncoding];
    return [[subclass alloc] initWithArgumentTypeEncoding:typeEncoding + fieldNameOffset];
}

+ (Class)argumentInputViewSubclassForTypeEncoding:(const char *)typeEncoding currentValue:(id)currentValue {
    // Remove the field name if there is any (e.g. \"width\"d -> d)
    const NSUInteger fieldNameOffset = [DSPRuntimeUtility fieldNameOffsetForTypeEncoding:typeEncoding];
    Class argumentInputViewSubclass = nil;
    NSArray<Class> *inputViewClasses = @[[DSPArgumentInputColorView class],
                                         [DSPArgumentInputFontView class],
                                         [DSPArgumentInputStringView class],
                                         [DSPArgumentInputStructView class],
                                         [DSPArgumentInputSwitchView class],
                                         [DSPArgumentInputDateView class],
                                         [DSPArgumentInputNumberView class],
                                         [DSPArgumentInputObjectView class]];

    // Note that order is important here since multiple subclasses may support the same type.
    // An example is the number subclass and the bool subclass for the type @encode(BOOL).
    // Both work, but we'd prefer to use the bool subclass.
    for (Class inputViewClass in inputViewClasses) {
        if ([inputViewClass supportsObjCType:typeEncoding + fieldNameOffset withCurrentValue:currentValue]) {
            argumentInputViewSubclass = inputViewClass;
            break;
        }
    }

    return argumentInputViewSubclass;
}

+ (BOOL)canEditFieldWithTypeEncoding:(const char *)typeEncoding currentValue:(id)currentValue {
    return [self argumentInputViewSubclassForTypeEncoding:typeEncoding currentValue:currentValue] != nil;
}

/// Enable displaying ivar names for custom struct types
+ (void)registerFieldNames:(NSArray<NSString *> *)names forTypeEncoding:(NSString *)typeEncoding {
    [DSPArgumentInputStructView registerFieldNames:names forTypeEncoding:typeEncoding];
}

@end
