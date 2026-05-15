#import "DSPFieldEditorViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface DSPDefaultEditorViewController : DSPVariableEditorViewController

+ (instancetype)target:(NSUserDefaults *)defaults key:(NSString *)key commitHandler:(void(^_Nullable)(void))onCommit;

+ (BOOL)canEditDefaultWithValue:(nullable id)currentValue;

@end

NS_ASSUME_NONNULL_END
