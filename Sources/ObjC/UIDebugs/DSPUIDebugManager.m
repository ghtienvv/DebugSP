#import "DSPUIDebugManager.h"

#import "DSPGlobalsDebugFactory.h"
#import "FHSViewController.h"
#import "DSPExplorerToolbar+FWDebug.h"
#import "DSPExplorerToolbar.h"
#import "DSPExplorerToolbarItem.h"
#import "DSPExplorerViewController+DSPRule.h"
#import "DSPGlobalsViewController.h"
#import "DSPHierarchyViewController.h"
#import "DSPManager+Private.h"
#import "DSPNavigationController.h"
#import "DSPUtility.h"

@interface DSPUIDebugManager ()

@property (nonatomic) BOOL toolbarConfigured;

@end

@implementation DSPUIDebugManager

+ (DSPUIDebugManager *)sharedManager {
    static DSPUIDebugManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (BOOL)isVisible {
    return !DSPManager.sharedManager.isHidden;
}

- (void)showMenu {
    [DSPGlobalsDebugFactory prepareRuntime];
    if (@available(iOS 13.0, *)) {
        [DSPManager.sharedManager showExplorerFromScene:DSPUtility.appKeyWindow.windowScene];
    } else {
        [DSPManager.sharedManager showExplorer];
    }
    [self configureToolbarIfNeeded];

    DSPExplorerViewController *explorer = [self explorerViewController];
    explorer.dsp_ruleEnabled = NO;
    [explorer dsp_resetToDefaultMode];
}

- (void)hideMenu {
    DSPExplorerViewController *explorer = [self explorerViewController];
    explorer.dsp_ruleEnabled = NO;
    [explorer dsp_resetToDefaultMode];
    [DSPManager.sharedManager dismissAnyPresentedTools:^{
        [DSPManager.sharedManager hideExplorer];
    }];
}

- (void)showSelectionExplorer {
    [self showMenu];
    DSPExplorerViewController *explorer = [self explorerViewController];
    explorer.dsp_ruleEnabled = NO;
    [explorer dsp_activateSelectMode];
}

- (DSPExplorerViewController *)explorerViewController {
    return DSPManager.sharedManager.explorerViewController;
}

- (void)configureToolbarIfNeeded {
    DSPExplorerToolbar *toolbar = DSPManager.sharedManager.toolbar;
    DSPExplorerViewController *explorer = [self explorerViewController];

    toolbar.toolbarItems = @[
        toolbar.selectItem,
        toolbar.fwDebugFpsItem,
        toolbar.hierarchyItem,
        toolbar.closeItem,
    ];
    toolbar.fwDebugFpsItem.fwDebugShowRuler = YES;

    [toolbar.selectItem removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [toolbar.fwDebugFpsItem removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [toolbar.hierarchyItem removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [toolbar.closeItem removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];

    [toolbar.selectItem addTarget:self action:@selector(selectItemTapped:) forControlEvents:UIControlEventTouchUpInside];
    [toolbar.fwDebugFpsItem addTarget:self action:@selector(ruleItemTapped:) forControlEvents:UIControlEventTouchUpInside];
    [toolbar.hierarchyItem addTarget:self action:@selector(viewsItemTapped:) forControlEvents:UIControlEventTouchUpInside];
    [toolbar.closeItem addTarget:self action:@selector(closeItemTapped:) forControlEvents:UIControlEventTouchUpInside];

    toolbar.selectItem.enabled = YES;
    toolbar.fwDebugFpsItem.enabled = YES;
    toolbar.hierarchyItem.enabled = YES;
    toolbar.closeItem.enabled = YES;
    toolbar.selectItem.fwDebugIsRuler = NO;
    toolbar.fwDebugFpsItem.selected = explorer.dsp_ruleEnabled;
}

- (void)selectItemTapped:(UIButton *)sender {
    DSPExplorerViewController *explorer = [self explorerViewController];
    if (explorer.dsp_ruleEnabled) {
        explorer.dsp_ruleEnabled = NO;
        return;
    }

    [explorer toggleSelectTool];

    BOOL isSelecting = [[explorer valueForKey:@"currentMode"] unsignedIntegerValue] == 1;
    if (!isSelecting) {
        explorer.dsp_ruleEnabled = NO;
        explorer.explorerToolbar.fwDebugFpsItem.selected = NO;
        [explorer dsp_removeRuleOverlay];
    }
}

- (void)ruleItemTapped:(UIButton *)sender {
    DSPExplorerViewController *explorer = [self explorerViewController];

    if (explorer.dsp_ruleEnabled) {
        [explorer dsp_resetToDefaultMode];
        return;
    }

    [explorer dsp_activateSelectMode];
    explorer.dsp_ruleEnabled = YES;
    [explorer dsp_removeRuleOverlay];
}

- (void)viewsItemTapped:(UIButton *)sender {
    DSPExplorerViewController *explorer = [self explorerViewController];
    [DSPManager.sharedManager presentTool:^UINavigationController *{
        UIView *selectedView = [explorer valueForKey:@"selectedView"];
        NSArray<UIView *> *viewsAtTap = [explorer valueForKey:@"viewsAtTapPoint"];
        if (selectedView && viewsAtTap.count) {
            return [DSPHierarchyViewController delegate:explorer viewsAtTap:viewsAtTap selectedView:selectedView];
        }
        return [DSPHierarchyViewController delegate:explorer];
    } completion:nil];
}

- (void)closeItemTapped:(UIButton *)sender {
    [self hideMenu];
}

@end
