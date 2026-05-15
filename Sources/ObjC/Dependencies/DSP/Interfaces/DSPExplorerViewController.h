#import "DSPExplorerToolbar.h"

@class DSPWindow;
@protocol DSPExplorerViewControllerDelegate;

/// A view controller that manages the DSP toolbar.
@interface DSPExplorerViewController : UIViewController

@property (nonatomic, weak) id <DSPExplorerViewControllerDelegate> delegate;
@property (nonatomic, readonly) BOOL wantsWindowToBecomeKey;

@property (nonatomic, readonly) DSPExplorerToolbar *explorerToolbar;

- (BOOL)shouldReceiveTouchAtWindowPoint:(CGPoint)pointInWindowCoordinates;

/// @brief Used to present (or dismiss) a modal view controller ("tool"),
/// typically triggered by pressing a button in the toolbar.
///
/// If a tool is already presented, this method simply dismisses it and calls the completion block.
/// If no tool is presented, @code future() @endcode is presented and the completion block is called.
- (void)toggleToolWithViewControllerProvider:(UINavigationController *(^)(void))future
                                  completion:(void (^)(void))completion;

/// @brief Used to present (or dismiss) a modal view controller ("tool"),
/// typically triggered by pressing a button in the toolbar.
///
/// If a tool is already presented, this method dismisses it and presents the given tool.
/// The completion block is called once the tool has been presented.
- (void)presentTool:(UINavigationController *(^)(void))future
         completion:(void (^)(void))completion;

// Keyboard shortcut helpers

- (void)toggleSelectTool;
- (void)toggleMoveTool;
- (void)toggleViewsTool;
- (void)toggleMenuTool;

/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleDownArrowKeyPressed;
/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleUpArrowKeyPressed;
/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleRightArrowKeyPressed;
/// @return YES if the explorer used the key press to perform an action, NO otherwise
- (BOOL)handleLeftArrowKeyPressed;

@end

#pragma mark -
@protocol DSPExplorerViewControllerDelegate <NSObject>
- (void)explorerViewControllerDidFinish:(DSPExplorerViewController *)explorerViewController;
@end
