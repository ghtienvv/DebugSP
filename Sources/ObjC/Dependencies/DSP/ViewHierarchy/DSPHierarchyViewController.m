#import "DSPHierarchyViewController.h"
#import "DSPHierarchyTableViewController.h"
#import "FHSViewController.h"
#import "DSPUtility.h"
#import "DSPTabList.h"
#import "DSPResources.h"
#import "UIBarButtonItem+DSP.h"

typedef NS_ENUM(NSUInteger, DSPHierarchyViewMode) {
    DSPHierarchyViewModeTree = 1,
    DSPHierarchyViewMode3DSnapshot
};

@interface DSPHierarchyViewController ()
@property (nonatomic, readonly, weak) id<DSPHierarchyDelegate> hierarchyDelegate;
@property (nonatomic, readonly) FHSViewController *snapshotViewController;
@property (nonatomic, readonly) DSPHierarchyTableViewController *treeViewController;

@property (nonatomic) DSPHierarchyViewMode mode;

@property (nonatomic, readonly) UIView *selectedView;
@end

@implementation DSPHierarchyViewController

#pragma mark - Initialization

+ (instancetype)delegate:(id<DSPHierarchyDelegate>)delegate {
    return [self delegate:delegate viewsAtTap:nil selectedView:nil];
}

+ (instancetype)delegate:(id<DSPHierarchyDelegate>)delegate
              viewsAtTap:(NSArray<UIView *> *)viewsAtTap
            selectedView:(UIView *)selectedView {
    return [[self alloc] initWithDelegate:delegate viewsAtTap:viewsAtTap selectedView:selectedView];
}

- (id)initWithDelegate:(id)delegate viewsAtTap:(NSArray<UIView *> *)viewsAtTap selectedView:(UIView *)view {
    self = [super init];
    if (self) {
        NSArray<UIWindow *> *allWindows = DSPUtility.allWindows;
        _hierarchyDelegate = delegate;
        _treeViewController = [DSPHierarchyTableViewController
            windows:allWindows viewsAtTap:viewsAtTap selectedView:view
        ];

        if (viewsAtTap) {
            _snapshotViewController = [FHSViewController snapshotViewsAtTap:viewsAtTap selectedView:view];
        } else {
            _snapshotViewController = [FHSViewController snapshotWindows:allWindows];
        }

        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }

    return self;
}


#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // 3D toggle button
    self.treeViewController.navigationItem.leftBarButtonItem = [UIBarButtonItem
        dsp_itemWithImage:DSPResources.toggle3DIcon target:self action:@selector(toggleHierarchyMode)
    ];

    // Dismiss when tree view row is selected
    __weak id<DSPHierarchyDelegate> delegate = self.hierarchyDelegate;
    self.treeViewController.didSelectRowAction = ^(UIView *selectedView) {
        [delegate viewHierarchyDidDismiss:selectedView];
    };

    // Start of in tree view
    _mode = DSPHierarchyViewModeTree;
    [self pushViewController:self.treeViewController animated:NO];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // Done button: manually added here because the hierarhcy screens need to actually pass
    // data back to the explorer view controller so that it can highlight selected views
    viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(donePressed)
    ];

    [super pushViewController:viewController animated:animated];
}


#pragma mark - Private

- (void)donePressed {
    // We need to manually close ourselves here because
    // DSPNavigationController doesn't ever close tabs itself 
    [DSPTabList.sharedList closeTab:self];
    [self.hierarchyDelegate viewHierarchyDidDismiss:self.selectedView];
}

- (void)toggleHierarchyMode {
    switch (self.mode) {
        case DSPHierarchyViewModeTree:
            self.mode = DSPHierarchyViewMode3DSnapshot;
            break;
        case DSPHierarchyViewMode3DSnapshot:
            self.mode = DSPHierarchyViewModeTree;
            break;
    }
}

- (void)setMode:(DSPHierarchyViewMode)mode {
    if (mode != _mode) {
        // The tree view controller is our top stack view controller, and
        // changing the mode simply pushes the snapshot view. In the future,
        // I would like to have the 3D toggle button transparently switch
        // between two views instead of pushing a new view controller.
        // This way the views should share the search controller somehow.
        switch (mode) {
            case DSPHierarchyViewModeTree:
                [self popViewControllerAnimated:NO];
                self.toolbarHidden = YES;
                self.treeViewController.selectedView = self.selectedView;
                break;
            case DSPHierarchyViewMode3DSnapshot:
                [self pushViewController:self.snapshotViewController animated:NO];
                self.toolbarHidden = NO;
                self.snapshotViewController.selectedView = self.selectedView;
                break;
        }

        // Change this last so that self.selectedView works right above
        _mode = mode;
    }
}

- (UIView *)selectedView {
    switch (self.mode) {
        case DSPHierarchyViewModeTree:
            return self.treeViewController.selectedView;
        case DSPHierarchyViewMode3DSnapshot:
            return self.snapshotViewController.selectedView;
    }
}

@end
