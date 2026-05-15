#import "DSPVariableEditorViewController.h"
#import "DSPProperty.h"
#import "DSPIvar.h"

NS_ASSUME_NONNULL_BEGIN

@interface DSPFieldEditorViewController : DSPVariableEditorViewController

/// @return nil if the property is readonly or if the type is unsupported
+ (nullable instancetype)target:(id)target property:(DSPProperty *)property commitHandler:(void(^_Nullable)(void))onCommit;
/// @return nil if the ivar type is unsupported
+ (nullable instancetype)target:(id)target ivar:(DSPIvar *)ivar commitHandler:(void(^_Nullable)(void))onCommit;

/// Subclasses can change the button title via the \c title property
@property (nonatomic, readonly) UIBarButtonItem *getterButton;

- (void)getterButtonPressed:(id)sender;

@end

NS_ASSUME_NONNULL_END
