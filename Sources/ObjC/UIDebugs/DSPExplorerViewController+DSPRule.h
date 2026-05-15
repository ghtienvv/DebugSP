#import "DSPExplorerViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface DSPExplorerViewController (DSPRule)

@property (nonatomic, assign) BOOL dsp_ruleEnabled;

- (void)dsp_activateSelectMode;
- (void)dsp_resetToDefaultMode;
- (void)dsp_removeRuleOverlay;

@end

NS_ASSUME_NONNULL_END
