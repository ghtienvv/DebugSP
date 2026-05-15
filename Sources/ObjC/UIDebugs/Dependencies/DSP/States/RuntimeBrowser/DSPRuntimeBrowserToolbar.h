#import "DSPKeyboardToolbar.h"
#import "DSPRuntimeKeyPath.h"

@interface DSPRuntimeBrowserToolbar : DSPKeyboardToolbar

+ (instancetype)toolbarWithHandler:(DSPKBToolbarAction)tapHandler suggestions:(NSArray<NSString *> *)suggestions;

- (void)setKeyPath:(DSPRuntimeKeyPath *)keyPath suggestions:(NSArray<NSString *> *)suggestions;

@end
