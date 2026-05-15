#import "DSPViewControllersViewController.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPMutableListSection.h"
#import "DSPUtility.h"

@interface DSPViewControllersViewController ()
@property (nonatomic, readonly) DSPMutableListSection *section;
@property (nonatomic, readonly) NSArray<UIViewController *> *controllers;
@end

@implementation DSPViewControllersViewController
@dynamic sections, allSections;

#pragma mark - Initialization

+ (instancetype)controllersForViews:(NSArray<UIView *> *)views {
    return [[self alloc] initWithViews:views];
}

- (id)initWithViews:(NSArray<UIView *> *)views {
    NSParameterAssert(views.count);
    
    self = [self initWithStyle:UITableViewStylePlain];
    if (self) {
        _controllers = [views dsp_mapped:^id(UIView *view, NSUInteger idx) {
            return [DSPUtility viewControllerForView:view];
        }];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"View Controllers at Tap";
    self.showsSearchBar = YES;
    [self disableToolbar];
}

- (NSArray<DSPTableViewSection *> *)makeSections {
    _section = [DSPMutableListSection list:self.controllers
        cellConfiguration:^(UITableViewCell *cell, UIViewController *controller, NSInteger row) {
            cell.textLabel.text = [NSString
                stringWithFormat:@"%@ — %p", NSStringFromClass(controller.class), controller
            ];
            cell.detailTextLabel.text = controller.view.description;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    } filterMatcher:^BOOL(NSString *filterText, UIViewController *controller) {
        return [NSStringFromClass(controller.class) localizedCaseInsensitiveContainsString:filterText];
    }];
    
    self.section.selectionHandler = ^(UIViewController *host, UIViewController *controller) {
        [host.navigationController pushViewController:
            [DSPObjectExplorerFactory explorerViewControllerForObject:controller]
        animated:YES];
    };
    
    self.section.customTitle = @"View Controllers";
    return @[self.section];
}


#pragma mark - Private

- (void)dismissAnimated {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
