#import "DSPManager+Extensibility.h"
#import "DSPManager+Private.h"
#import "DSPNavigationController.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPKeyboardShortcutManager.h"
#import "DSPExplorerViewController.h"
#import "DSPNetworkMITMViewController.h"
#import "DSPKeyboardHelpViewController.h"
#import "DSPFileBrowserController.h"
#import "DSPArgumentInputStructView.h"
#import "DSPUtility.h"

@interface DSPManager (ExtensibilityPrivate)
@property (nonatomic, readonly) UIViewController *topViewController;
@end

@implementation DSPManager (Extensibility)

#pragma mark - Globals Screen Entries

- (void)registerGlobalEntryWithName:(NSString *)entryName objectFutureBlock:(id (^)(void))objectFutureBlock {
    NSParameterAssert(entryName);
    NSParameterAssert(objectFutureBlock);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    entryName = entryName.copy;
    DSPGlobalsEntry *entry = [DSPGlobalsEntry entryWithNameFuture:^NSString *{
        return entryName;
    } viewControllerFuture:^UIViewController *{
        return [DSPObjectExplorerFactory explorerViewControllerForObject:objectFutureBlock()];
    }];

    [self.userGlobalEntries addObject:entry];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName viewControllerFutureBlock:(UIViewController * (^)(void))viewControllerFutureBlock {
    NSParameterAssert(entryName);
    NSParameterAssert(viewControllerFutureBlock);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");

    entryName = entryName.copy;
    DSPGlobalsEntry *entry = [DSPGlobalsEntry entryWithNameFuture:^NSString *{
        return entryName;
    } viewControllerFuture:^UIViewController *{
        UIViewController *viewController = viewControllerFutureBlock();
        NSCAssert(viewController, @"'%@' entry returned nil viewController. viewControllerFutureBlock should never return nil.", entryName);
        return viewController;
    }];

    [self.userGlobalEntries addObject:entry];
}

- (void)registerGlobalEntryWithName:(NSString *)entryName action:(DSPGlobalsEntryRowAction)rowSelectedAction {
    NSParameterAssert(entryName);
    NSParameterAssert(rowSelectedAction);
    NSAssert(NSThread.isMainThread, @"This method must be called from the main thread.");
    
    entryName = entryName.copy;
    DSPGlobalsEntry *entry = [DSPGlobalsEntry entryWithNameFuture:^NSString * _Nonnull{
        return entryName;
    } action:rowSelectedAction];
    
    [self.userGlobalEntries addObject:entry];
}

- (void)clearGlobalEntries {
    [self.userGlobalEntries removeAllObjects];
}


#pragma mark - Editing

+ (void)registerFieldNames:(NSArray<NSString *> *)names forTypeEncoding:(NSString *)typeEncoding {
    [DSPArgumentInputStructView registerFieldNames:names forTypeEncoding:typeEncoding];
}


#pragma mark - Simulator Shortcuts

- (void)registerSimulatorShortcutWithKey:(NSString *)key modifiers:(UIKeyModifierFlags)modifiers action:(dispatch_block_t)action description:(NSString *)description {
#if TARGET_OS_SIMULATOR
    [DSPKeyboardShortcutManager.sharedManager registerSimulatorShortcutWithKey:key modifiers:modifiers action:action description:description allowOverride:YES];
#endif
}

- (void)setSimulatorShortcutsEnabled:(BOOL)simulatorShortcutsEnabled {
#if TARGET_OS_SIMULATOR
    [DSPKeyboardShortcutManager.sharedManager setEnabled:simulatorShortcutsEnabled];
#endif
}

- (BOOL)simulatorShortcutsEnabled {
#if TARGET_OS_SIMULATOR
    return DSPKeyboardShortcutManager.sharedManager.isEnabled;
#else
    return NO;
#endif
}


#pragma mark - Shortcuts Defaults

- (void)registerDefaultSimulatorShortcutWithKey:(NSString *)key modifiers:(UIKeyModifierFlags)modifiers action:(dispatch_block_t)action description:(NSString *)description {
#if TARGET_OS_SIMULATOR
    // Don't allow override to avoid changing keys registered by the app
    [DSPKeyboardShortcutManager.sharedManager registerSimulatorShortcutWithKey:key modifiers:modifiers action:action description:description allowOverride:NO];
#endif
}

- (void)registerDefaultSimulatorShortcuts {
    [self registerDefaultSimulatorShortcutWithKey:@"f" modifiers:0 action:^{
        [self toggleExplorer];
    } description:@"Toggle DSP toolbar"];

    [self registerDefaultSimulatorShortcutWithKey:@"g" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleMenuTool];
    } description:@"Toggle DSP globals menu"];

    [self registerDefaultSimulatorShortcutWithKey:@"v" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleViewsTool];
    } description:@"Toggle view hierarchy menu"];

    [self registerDefaultSimulatorShortcutWithKey:@"s" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleSelectTool];
    } description:@"Toggle select tool"];

    [self registerDefaultSimulatorShortcutWithKey:@"m" modifiers:0 action:^{
        [self showExplorerIfNeeded];
        [self.explorerViewController toggleMoveTool];
    } description:@"Toggle move tool"];

    [self registerDefaultSimulatorShortcutWithKey:@"n" modifiers:0 action:^{
        [self toggleTopViewControllerOfClass:[DSPNetworkMITMViewController class]];
    } description:@"Toggle network history view"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputDownArrow modifiers:0 action:^{
        if (self.isHidden || ![self.explorerViewController handleDownArrowKeyPressed]) {
            [self tryScrollDown];
        }
    } description:@"Cycle view selection\n\t\tMove view down\n\t\tScroll down"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputUpArrow modifiers:0 action:^{
        if (self.isHidden || ![self.explorerViewController handleUpArrowKeyPressed]) {
            [self tryScrollUp];
        }
    } description:@"Cycle view selection\n\t\tMove view up\n\t\tScroll up"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputRightArrow modifiers:0 action:^{
        if (!self.isHidden) {
            [self.explorerViewController handleRightArrowKeyPressed];
        }
    } description:@"Move selected view right"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputLeftArrow modifiers:0 action:^{
        if (self.isHidden) {
            [self tryGoBack];
        } else {
            [self.explorerViewController handleLeftArrowKeyPressed];
        }
    } description:@"Move selected view left"];

    [self registerDefaultSimulatorShortcutWithKey:@"?" modifiers:0 action:^{
        [self toggleTopViewControllerOfClass:[DSPKeyboardHelpViewController class]];
    } description:@"Toggle (this) help menu"];

    [self registerDefaultSimulatorShortcutWithKey:UIKeyInputEscape modifiers:0 action:^{
        [[self.topViewController presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    } description:@"End editing text\n\t\tDismiss top view controller"];

    [self registerDefaultSimulatorShortcutWithKey:@"o" modifiers:UIKeyModifierCommand|UIKeyModifierShift action:^{
        [self toggleTopViewControllerOfClass:[DSPFileBrowserController class]];
    } description:@"Toggle file browser menu"];
}

+ (void)load {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.sharedManager registerDefaultSimulatorShortcuts];
    });
}


#pragma mark - Private

- (UIEdgeInsets)contentInsetsOfScrollView:(UIScrollView *)scrollView {
    if (@available(iOS 11, *)) {
        return scrollView.adjustedContentInset;
    }

    return scrollView.contentInset;
}

- (void)tryScrollDown {
    UIScrollView *scrollview = [self firstScrollView];
    UIEdgeInsets insets = [self contentInsetsOfScrollView:scrollview];
    CGPoint contentOffset = scrollview.contentOffset;
    CGFloat maxYOffset = scrollview.contentSize.height - scrollview.bounds.size.height + insets.bottom;
    contentOffset.y = MIN(contentOffset.y + 200, maxYOffset);
    [scrollview setContentOffset:contentOffset animated:YES];
}

- (void)tryScrollUp {
    UIScrollView *scrollview = [self firstScrollView];
    UIEdgeInsets insets = [self contentInsetsOfScrollView:scrollview];
    CGPoint contentOffset = scrollview.contentOffset;
    contentOffset.y = MAX(contentOffset.y - 200, -insets.top);
    [scrollview setContentOffset:contentOffset animated:YES];
}

- (UIScrollView *)firstScrollView {
    NSMutableArray<UIView *> *views = DSPUtility.appKeyWindow.subviews.mutableCopy;
    UIScrollView *scrollView = nil;
    while (views.count > 0) {
        UIView *view = views.firstObject;
        [views removeObjectAtIndex:0];
        if ([view isKindOfClass:[UIScrollView class]]) {
            scrollView = (UIScrollView *)view;
            break;
        } else {
            [views addObjectsFromArray:view.subviews];
        }
    }
    return scrollView;
}

- (void)tryGoBack {
    UINavigationController *navigationController = nil;
    UIViewController *topViewController = self.topViewController;
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        navigationController = (UINavigationController *)topViewController;
    } else {
        navigationController = topViewController.navigationController;
    }
    [navigationController popViewControllerAnimated:YES];
}

- (UIViewController *)topViewController {
    return [DSPUtility topViewControllerInWindow:UIApplication.sharedApplication.keyWindow];
}

- (void)toggleTopViewControllerOfClass:(Class)class {
    UINavigationController *topViewController = (id)self.topViewController;
    if ([topViewController isKindOfClass:[DSPNavigationController class]]) {
        if ([topViewController.topViewController isKindOfClass:[class class]]) {
            if (topViewController.viewControllers.count == 1) {
                // Dismiss since we are already presenting it
                [topViewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            } else {
                // Pop since we are viewing it but it's not the only thing on the stack
                [topViewController popViewControllerAnimated:YES];
            }
        } else {
            // Push it on the existing navigation stack
            [topViewController pushViewController:[class new] animated:YES];
        }
    } else {
        // Present it in an entirely new navigation controller
        [self.explorerViewController presentViewController:
            [DSPNavigationController withRootViewController:[class new]]
        animated:YES completion:nil];
    }
}

- (void)showExplorerIfNeeded {
    if (self.isHidden) {
        [self showExplorer];
    }
}

@end
