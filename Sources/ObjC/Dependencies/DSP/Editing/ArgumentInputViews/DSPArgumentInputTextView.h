#import "DSPArgumentInputView.h"

@interface DSPArgumentInputTextView : DSPArgumentInputView <UITextViewDelegate>

// For subclass eyes only

@property (nonatomic, readonly) UITextView *inputTextView;
@property (nonatomic) NSString *inputPlaceholderText;

@end
