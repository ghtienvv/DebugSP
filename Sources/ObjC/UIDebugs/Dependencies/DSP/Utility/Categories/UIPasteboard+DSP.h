#import <UIKit/UIKit.h>

@interface UIPasteboard (DSP)

/// For copying an object which could be a string, data, or number
- (void)dsp_copy:(id)unknownType;

@end
