#import "DSPObjcRuntimeViewController.h"
#import "DSPKeyPathSearchController.h"
#import "DSPRuntimeBrowserToolbar.h"
#import "UIGestureRecognizer+Blocks.h"
#import "UIBarButtonItem+DSP.h"
#import "DSPTableView.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPAlert.h"
#import "DSPRuntimeClient.h"
#import <dlfcn.h>

@interface DSPObjcRuntimeViewController () <DSPKeyPathSearchControllerDelegate>

@property (nonatomic, readonly ) DSPKeyPathSearchController *keyPathController;
@property (nonatomic, readonly ) UIView *promptView;

@end

@implementation DSPObjcRuntimeViewController

#pragma mark - Setup, view events

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Long press on navigation bar to initialize webkit legacy
    //
    // We call initializeWebKitLegacy automatically before you search
    // all bundles just to be safe (since touching some classes before
    // WebKit is initialized will initialize it on a thread other than
    // the main thread), but sometimes you can encounter this crash
    // without searching through all bundles, of course.
    [self.navigationController.navigationBar addGestureRecognizer:[
        [UILongPressGestureRecognizer alloc]
            initWithTarget:[DSPRuntimeClient class]
            action:@selector(initializeWebKitLegacy)
        ]
    ];
    
    [self addToolbarItems:@[DSPBarButtonItem(@"dlopen()", self, @selector(dlopenPressed:))]];
    
    // Search bar stuff, must be first because this creates self.searchController
    self.showsSearchBar = YES;
    self.showSearchBarInitially = YES;
    self.activatesSearchBarAutomatically = YES;
    // Using pinSearchBar on this screen causes a weird visual
    // thing on the next view controller that gets pushed.
    //
    // self.pinSearchBar = YES;
    self.searchController.searchBar.placeholder = @"UIKit*.UIView.-setFrame:";

    // Search controller stuff
    // key path controller automatically assigns itself as the delegate of the search bar
    // To avoid a retain cycle below, use local variables
    UISearchBar *searchBar = self.searchController.searchBar;
    DSPKeyPathSearchController *keyPathController = [DSPKeyPathSearchController delegate:self];
    _keyPathController = keyPathController;
    _keyPathController.toolbar = [DSPRuntimeBrowserToolbar toolbarWithHandler:^(NSString *text, BOOL suggestion) {
        if (suggestion) {
            [keyPathController didSelectKeyPathOption:text];
        } else {
            [keyPathController didPressButton:text insertInto:searchBar];
        }
    } suggestions:keyPathController.suggestions];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}


#pragma mark dlopen

/// Prompt user for dlopen shortcuts to choose from
- (void)dlopenPressed:(id)sender {
    [DSPAlert makeAlert:^(DSPAlert *make) {
        make.title(@"Dynamically Open Library");
        make.message(@"Invoke dlopen() with the given path. Choose an option below.");
        
        make.button(@"System Framework").handler(^(NSArray<NSString *> *_) {
            [self dlopenWithFormat:@"/System/Library/Frameworks/%@.framework/%@"];
        });
        make.button(@"System Private Framework").handler(^(NSArray<NSString *> *_) {
            [self dlopenWithFormat:@"/System/Library/PrivateFrameworks/%@.framework/%@"];
        });
        make.button(@"Arbitrary Binary").handler(^(NSArray<NSString *> *_) {
            [self dlopenWithFormat:nil];
        });
        
        make.button(@"Cancel").cancelStyle();
    } showFrom:self];
}

/// Prompt user for input and dlopen
- (void)dlopenWithFormat:(NSString *)format {
    [DSPAlert makeAlert:^(DSPAlert *make) {
        make.title(@"Dynamically Open Library");
        if (format) {
            make.message(@"Pass in a framework name, such as CarKit or FrontBoard.");
        } else {
            make.message(@"Pass in an absolute path to a binary.");
        }
        
        make.textField(format ? @"ARKit" : @"/System/Library/Frameworks/ARKit.framework/ARKit");
        
        make.button(@"Cancel").cancelStyle();
        make.button(@"Open").destructiveStyle().handler(^(NSArray<NSString *> *strings) {
            NSString *path = strings[0];
            
            if (path.length < 2) {
                [self dlopenInvalidPath];
            } else if (format) {
                path = [NSString stringWithFormat:format, path, path];
            }
            
            if (!dlopen(path.UTF8String, RTLD_NOW)) {
                [DSPAlert makeAlert:^(DSPAlert *make) {
                    make.title(@"Error").message(@(dlerror()));
                    make.button(@"Dismiss").cancelStyle();
                }];
            }
        });
    } showFrom:self];
}

- (void)dlopenInvalidPath {
    [DSPAlert makeAlert:^(DSPAlert * _Nonnull make) {
        make.title(@"Path or Name Too Short");
        make.button(@"Dismiss").cancelStyle();
    } showFrom:self];
}


#pragma mark Delegate stuff

- (void)didSelectImagePath:(NSString *)path shortName:(NSString *)shortName {
    [DSPAlert makeAlert:^(DSPAlert *make) {
        make.title(shortName);
        make.message(@"No NSBundle associated with this path:\n\n");
        make.message(path);

        make.button(@"Copy Path").handler(^(NSArray<NSString *> *strings) {
            UIPasteboard.generalPasteboard.string = path;
        });
        make.button(@"Dismiss").cancelStyle();
    } showFrom:self];
}

- (void)didSelectBundle:(NSBundle *)bundle {
    NSParameterAssert(bundle);
    DSPObjectExplorerViewController *explorer = [DSPObjectExplorerFactory explorerViewControllerForObject:bundle];
    [self.navigationController pushViewController:explorer animated:YES];
}

- (void)didSelectClass:(Class)cls {
    NSParameterAssert(cls);
    DSPObjectExplorerViewController *explorer = [DSPObjectExplorerFactory explorerViewControllerForObject:cls];
    [self.navigationController pushViewController:explorer animated:YES];
}


#pragma mark - DSPGlobalsEntry

+ (NSString *)globalsEntryTitle:(DSPGlobalsRow)row {
    return @"📚  Runtime Browser";
}

+ (UIViewController *)globalsEntryViewController:(DSPGlobalsRow)row {
    UIViewController *controller = [self new];
    controller.title = [self globalsEntryTitle:row];
    return controller;
}

@end
