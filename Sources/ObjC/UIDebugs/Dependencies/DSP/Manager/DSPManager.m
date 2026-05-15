#import "DSPManager.h"
#import "DSPUtility.h"
#import "DSPExplorerViewController.h"
#import "DSPWindow.h"
#import "DSPNavigationController.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPFileBrowserController.h"

@interface DSPManager () <DSPWindowEventDelegate, DSPExplorerViewControllerDelegate>

@property (nonatomic, readonly, getter=isHidden) BOOL hidden;

@property (nonatomic) DSPWindow *explorerWindow;
@property (nonatomic) DSPExplorerViewController *explorerViewController;

@property (nonatomic, readonly) NSMutableArray<DSPGlobalsEntry *> *userGlobalEntries;
@property (nonatomic, readonly) NSMutableDictionary<NSString *, DSPCustomContentViewerFuture> *customContentTypeViewers;

@end

@implementation DSPManager

+ (instancetype)sharedManager {
    static DSPManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _userGlobalEntries = [NSMutableArray new];
        _customContentTypeViewers = [NSMutableDictionary new];
    }
    return self;
}

- (DSPWindow *)explorerWindow {
    NSAssert(NSThread.isMainThread, @"You must use %@ from the main thread only.", NSStringFromClass([self class]));
    
    if (!_explorerWindow) {
        _explorerWindow = [[DSPWindow alloc] initWithFrame:DSPUtility.appKeyWindow.bounds];
        _explorerWindow.eventDelegate = self;
        _explorerWindow.rootViewController = self.explorerViewController;
    }
    
    return _explorerWindow;
}

- (DSPExplorerViewController *)explorerViewController {
    if (!_explorerViewController) {
        _explorerViewController = [DSPExplorerViewController new];
        _explorerViewController.delegate = self;
    }

    return _explorerViewController;
}

- (void)showExplorer {
    UIWindow *dsp = self.explorerWindow;
    dsp.hidden = NO;
    if (@available(iOS 13.0, *)) {
        // Only look for a new scene if we don't have one
        if (!dsp.windowScene) {
            dsp.windowScene = DSPUtility.appKeyWindow.windowScene;
        }
    }
}

- (void)hideExplorer {
    self.explorerWindow.hidden = YES;
}

- (void)toggleExplorer {
    if (self.explorerWindow.isHidden) {
        if (@available(iOS 13.0, *)) {
            [self showExplorerFromScene:DSPUtility.appKeyWindow.windowScene];
        } else {
            [self showExplorer];
        }
    } else {
        [self hideExplorer];
    }
}

- (void)dismissAnyPresentedTools:(void (^)(void))completion {
    if (self.explorerViewController.presentedViewController) {
        [self.explorerViewController dismissViewControllerAnimated:YES completion:completion];
    } else if (completion) {
        completion();
    }
}

- (void)presentTool:(UINavigationController * _Nonnull (^)(void))future completion:(void (^)(void))completion {
    [self showExplorer];
    [self.explorerViewController presentTool:future completion:completion];
}

- (void)presentEmbeddedTool:(UIViewController *)tool completion:(void (^)(UINavigationController *))completion {
    DSPNavigationController *nav = [DSPNavigationController withRootViewController:tool];
    [self presentTool:^UINavigationController *{
        return nav;
    } completion:^{
        if (completion) completion(nav);
    }];
}

- (void)presentObjectExplorer:(id)object completion:(void (^)(UINavigationController *))completion {
    UIViewController *explorer = [DSPObjectExplorerFactory explorerViewControllerForObject:object];
    [self presentEmbeddedTool:explorer completion:completion];
}

- (void)showExplorerFromScene:(UIWindowScene *)scene {
    if (@available(iOS 13.0, *)) {
        self.explorerWindow.windowScene = scene;
    }
    self.explorerWindow.hidden = NO;
}

- (BOOL)isHidden {
    return self.explorerWindow.isHidden;
}

- (DSPExplorerToolbar *)toolbar {
    return self.explorerViewController.explorerToolbar;
}


#pragma mark - DSPWindowEventDelegate

- (BOOL)shouldHandleTouchAtPoint:(CGPoint)pointInWindow {
    // Ask the explorer view controller
    return [self.explorerViewController shouldReceiveTouchAtWindowPoint:pointInWindow];
}

- (BOOL)canBecomeKeyWindow {
    // Only when the explorer view controller wants it because
    // it needs to accept key input & affect the status bar.
    return self.explorerViewController.wantsWindowToBecomeKey;
}


#pragma mark - DSPExplorerViewControllerDelegate

- (void)explorerViewControllerDidFinish:(DSPExplorerViewController *)explorerViewController {
    [self hideExplorer];
}

@end
