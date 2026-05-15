#import "UITextField+Range.h"

@implementation UITextField (Range)

- (NSRange)dsp_selectedRange {
    UITextRange *r = self.selectedTextRange;
    if (r) {
        NSInteger loc = [self offsetFromPosition:self.beginningOfDocument toPosition:r.start];
        NSInteger len = [self offsetFromPosition:r.start toPosition:r.end];
        return NSMakeRange(loc, len);
    }

    return NSMakeRange(NSNotFound, 0);
}

@end
