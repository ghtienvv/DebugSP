#import "DSPKBToolbarButton.h"

@interface DSPKeyboardToolbar : UIView

+ (instancetype)toolbarWithButtons:(NSArray *)buttons;

@property (nonatomic) NSArray<DSPKBToolbarButton*> *buttons;
@property (nonatomic) UIKeyboardAppearance appearance;

@end
