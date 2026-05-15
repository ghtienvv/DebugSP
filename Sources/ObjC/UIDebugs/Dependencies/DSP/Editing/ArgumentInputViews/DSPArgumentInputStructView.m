#import "DSPArgumentInputStructView.h"
#import "DSPArgumentInputViewFactory.h"
#import "DSPRuntimeUtility.h"
#import "DSPTypeEncodingParser.h"

@interface DSPArgumentInputStructView ()

@property (nonatomic) NSArray<DSPArgumentInputView *> *argumentInputViews;

@end

@implementation DSPArgumentInputStructView

static NSMutableDictionary<NSString *, NSArray<NSString *> *> *structFieldNameRegistrar = nil;
+ (void)initialize {
    if (self == [DSPArgumentInputStructView class]) {
        structFieldNameRegistrar = [NSMutableDictionary new];
        [self registerDefaultFieldNames];
    }
}

+ (void)registerDefaultFieldNames {
    NSDictionary *defaults = @{
        @(@encode(CGRect)):             @[@"CGPoint origin", @"CGSize size"],
        @(@encode(CGPoint)):            @[@"CGFloat x", @"CGFloat y"],
        @(@encode(CGSize)):             @[@"CGFloat width", @"CGFloat height"],
        @(@encode(CGVector)):           @[@"CGFloat dx", @"CGFloat dy"],
        @(@encode(UIEdgeInsets)):       @[@"CGFloat top", @"CGFloat left", @"CGFloat bottom", @"CGFloat right"],
        @(@encode(UIOffset)):           @[@"CGFloat horizontal", @"CGFloat vertical"],
        @(@encode(NSRange)):            @[@"NSUInteger location", @"NSUInteger length"],
        @(@encode(CATransform3D)):      @[@"CGFloat m11", @"CGFloat m12", @"CGFloat m13", @"CGFloat m14",
                                          @"CGFloat m21", @"CGFloat m22", @"CGFloat m23", @"CGFloat m24",
                                          @"CGFloat m31", @"CGFloat m32", @"CGFloat m33", @"CGFloat m34",
                                          @"CGFloat m41", @"CGFloat m42", @"CGFloat m43", @"CGFloat m44"],
        @(@encode(CGAffineTransform)):  @[@"CGFloat a", @"CGFloat b",
                                          @"CGFloat c", @"CGFloat d",
                                          @"CGFloat tx", @"CGFloat ty"],
    };
    
    [structFieldNameRegistrar addEntriesFromDictionary:defaults];
    
    if (@available(iOS 11.0, *)) {
        structFieldNameRegistrar[@(@encode(NSDirectionalEdgeInsets))] = @[
            @"CGFloat top", @"CGFloat leading", @"CGFloat bottom", @"CGFloat trailing"
        ];
    }
}

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        NSMutableArray<DSPArgumentInputView *> *inputViews = [NSMutableArray new];
        NSArray<NSString *> *customTitles = [[self class] customFieldTitlesForTypeEncoding:typeEncoding];
        [DSPRuntimeUtility enumerateTypesInStructEncoding:typeEncoding usingBlock:^(NSString *structName,
                                                                                     const char *fieldTypeEncoding,
                                                                                     NSString *prettyTypeEncoding,
                                                                                     NSUInteger fieldIndex,
                                                                                     NSUInteger fieldOffset) {
            
            DSPArgumentInputView *inputView = [DSPArgumentInputViewFactory argumentInputViewForTypeEncoding:fieldTypeEncoding];
            inputView.targetSize = DSPArgumentInputViewSizeSmall;
            
            if (fieldIndex < customTitles.count) {
                inputView.title = customTitles[fieldIndex];
            } else {
                inputView.title = [NSString stringWithFormat:@"%@ field %lu (%@)",
                    structName, (unsigned long)fieldIndex, prettyTypeEncoding
                ];
            }

            [inputViews addObject:inputView];
            [self addSubview:inputView];
        }];
        self.argumentInputViews = inputViews;
    }
    return self;
}


#pragma mark - Superclass Overrides

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    [super setBackgroundColor:backgroundColor];
    for (DSPArgumentInputView *inputView in self.argumentInputViews) {
        inputView.backgroundColor = backgroundColor;
    }
}

- (void)setInputValue:(id)inputValue {
    if ([inputValue isKindOfClass:[NSValue class]]) {
        const char *structTypeEncoding = [inputValue objCType];
        if (strcmp(self.typeEncoding.UTF8String, structTypeEncoding) == 0) {
            NSUInteger valueSize = 0;
            
            if (DSPGetSizeAndAlignment(structTypeEncoding, &valueSize, NULL)) {
                void *unboxedValue = malloc(valueSize);
                [inputValue getValue:unboxedValue];
                [DSPRuntimeUtility enumerateTypesInStructEncoding:structTypeEncoding usingBlock:^(NSString *structName,
                                                                                                   const char *fieldTypeEncoding,
                                                                                                   NSString *prettyTypeEncoding,
                                                                                                   NSUInteger fieldIndex,
                                                                                                   NSUInteger fieldOffset) {
                    
                    void *fieldPointer = unboxedValue + fieldOffset;
                    DSPArgumentInputView *inputView = self.argumentInputViews[fieldIndex];
                    
                    if (fieldTypeEncoding[0] == DSPTypeEncodingObjcObject || fieldTypeEncoding[0] == DSPTypeEncodingObjcClass) {
                        inputView.inputValue = (__bridge id)fieldPointer;
                    } else {
                        NSValue *boxedField = [DSPRuntimeUtility valueForPrimitivePointer:fieldPointer objCType:fieldTypeEncoding];
                        inputView.inputValue = boxedField;
                    }
                }];
                free(unboxedValue);
            }
        }
    }
}

- (id)inputValue {
    NSValue *boxedStruct = nil;
    const char *structTypeEncoding = self.typeEncoding.UTF8String;
    NSUInteger structSize = 0;
    
    if (DSPGetSizeAndAlignment(structTypeEncoding, &structSize, NULL)) {
        void *unboxedStruct = malloc(structSize);
        [DSPRuntimeUtility enumerateTypesInStructEncoding:structTypeEncoding usingBlock:^(NSString *structName,
                                                                                           const char *fieldTypeEncoding,
                                                                                           NSString *prettyTypeEncoding,
                                                                                           NSUInteger fieldIndex,
                                                                                           NSUInteger fieldOffset) {
            
            void *fieldPointer = unboxedStruct + fieldOffset;
            DSPArgumentInputView *inputView = self.argumentInputViews[fieldIndex];
            
            if (fieldTypeEncoding[0] == DSPTypeEncodingObjcObject || fieldTypeEncoding[0] == DSPTypeEncodingObjcClass) {
                // Object fields
                memcpy(fieldPointer, (__bridge void *)inputView.inputValue, sizeof(id));
            } else {
                // Boxed primitive/struct fields
                id inputValue = inputView.inputValue;
                if ([inputValue isKindOfClass:[NSValue class]] && strcmp([inputValue objCType], fieldTypeEncoding) == 0) {
                    [inputValue getValue:fieldPointer];
                }
            }
        }];
        
        boxedStruct = [NSValue value:unboxedStruct withObjCType:structTypeEncoding];
        free(unboxedStruct);
    }
    
    return boxedStruct;
}

- (BOOL)inputViewIsFirstResponder {
    BOOL isFirstResponder = NO;
    for (DSPArgumentInputView *inputView in self.argumentInputViews) {
        if ([inputView inputViewIsFirstResponder]) {
            isFirstResponder = YES;
            break;
        }
    }
    return isFirstResponder;
}


#pragma mark - Layout and Sizing

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat runningOriginY = self.topInputFieldVerticalLayoutGuide;
    
    for (DSPArgumentInputView *inputView in self.argumentInputViews) {
        CGSize inputFitSize = [inputView sizeThatFits:self.bounds.size];
        inputView.frame = CGRectMake(0, runningOriginY, inputFitSize.width, inputFitSize.height);
        runningOriginY = CGRectGetMaxY(inputView.frame) + [[self class] verticalPaddingBetweenFields];
    }
}

+ (CGFloat)verticalPaddingBetweenFields {
    return 10.0;
}

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize fitSize = [super sizeThatFits:size];
    
    CGSize constrainSize = CGSizeMake(size.width, CGFLOAT_MAX);
    CGFloat height = fitSize.height;
    
    for (DSPArgumentInputView *inputView in self.argumentInputViews) {
        height += [inputView sizeThatFits:constrainSize].height;
        height += [[self class] verticalPaddingBetweenFields];
    }
    
    return CGSizeMake(fitSize.width, height);
}


#pragma mark - Class Helpers

+ (BOOL)supportsObjCType:(const char *)type withCurrentValue:(id)value {
    NSParameterAssert(type);
    if (type[0] == DSPTypeEncodingStructBegin) {
        return DSPGetSizeAndAlignment(type, nil, nil);
    }

    return NO;
}

+ (void)registerFieldNames:(NSArray<NSString *> *)names forTypeEncoding:(NSString *)typeEncoding {
    NSParameterAssert(typeEncoding); NSParameterAssert(names);
    structFieldNameRegistrar[typeEncoding] = names;
}

+ (NSArray<NSString *> *)customFieldTitlesForTypeEncoding:(const char *)typeEncoding {
    return structFieldNameRegistrar[@(typeEncoding)];
}

@end
