#import "DSPArgumentInputNotSupportedView.h"
#import "DSPColor.h"

@implementation DSPArgumentInputNotSupportedView

- (instancetype)initWithArgumentTypeEncoding:(const char *)typeEncoding {
    self = [super initWithArgumentTypeEncoding:typeEncoding];
    if (self) {
        self.inputTextView.userInteractionEnabled = NO;
        self.inputTextView.backgroundColor = [DSPColor secondaryGroupedBackgroundColorWithAlpha:0.5];
        self.inputPlaceholderText = @"nil  (type not supported)";
        self.targetSize = DSPArgumentInputViewSizeSmall;
    }
    return self;
}

@end
