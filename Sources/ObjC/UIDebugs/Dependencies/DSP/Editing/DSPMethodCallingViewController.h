#import "DSPVariableEditorViewController.h"
#import "DSPMethod.h"

@interface DSPMethodCallingViewController : DSPVariableEditorViewController

+ (instancetype)target:(id)target method:(DSPMethod *)method;

@end
