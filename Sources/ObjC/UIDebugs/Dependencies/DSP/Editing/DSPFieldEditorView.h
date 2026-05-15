#import <UIKit/UIKit.h>

@class DSPArgumentInputView;

@interface DSPFieldEditorView : UIView

@property (nonatomic, copy) NSString *targetDescription;
@property (nonatomic, copy) NSString *fieldDescription;

@property (nonatomic, copy) NSArray<DSPArgumentInputView *> *argumentInputViews;

@end
