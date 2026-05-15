#import "DSPSearchToken.h"

@interface DSPSearchToken () {
    NSString *dsp_description;
}
@end

@implementation DSPSearchToken

+ (instancetype)any {
    static DSPSearchToken *any = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        any = [self string:nil options:TBWildcardOptionsAny];
    });

    return any;
}

+ (instancetype)string:(NSString *)string options:(TBWildcardOptions)options {
    DSPSearchToken *token  = [self new];
    token->_string  = string;
    token->_options = options;
    return token;
}

- (BOOL)isAbsolute {
    return _options == TBWildcardOptionsNone;
}

- (BOOL)isAny {
    return _options == TBWildcardOptionsAny;
}

- (BOOL)isEmpty {
    return self.isAny && self.string.length == 0;
}

- (NSString *)description {
    if (dsp_description) {
        return dsp_description;
    }

    switch (_options) {
        case TBWildcardOptionsNone:
            dsp_description = _string;
            break;
        case TBWildcardOptionsAny:
            dsp_description = @"*";
            break;
        default: {
            NSMutableString *desc = [NSMutableString new];
            if (_options & TBWildcardOptionsPrefix) {
                [desc appendString:@"*"];
            }
            [desc appendString:_string];
            if (_options & TBWildcardOptionsSuffix) {
                [desc appendString:@"*"];
            }
            dsp_description = desc;
        }
    }

    return dsp_description;
}

- (NSUInteger)hash {
    return self.description.hash;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[DSPSearchToken class]]) {
        DSPSearchToken *token = object;
        return [_string isEqualToString:token->_string] && _options == token->_options;
    }

    return NO;
}

@end
