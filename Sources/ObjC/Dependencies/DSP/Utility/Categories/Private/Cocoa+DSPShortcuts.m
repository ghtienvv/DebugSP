#import "Cocoa+DSPShortcuts.h"

@implementation UIAlertAction (DSPShortcuts)
- (NSString *)dsp_styleName {
    switch (self.style) {
        case UIAlertActionStyleDefault:
            return @"Default style";
        case UIAlertActionStyleCancel:
            return @"Cancel style";
        case UIAlertActionStyleDestructive:
            return @"Destructive style";
            
        default:
            return [NSString stringWithFormat:@"Unknown (%@)", @(self.style)];
    }
}
@end
