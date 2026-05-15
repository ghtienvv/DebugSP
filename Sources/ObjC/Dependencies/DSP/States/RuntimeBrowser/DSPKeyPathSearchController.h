#import <UIKit/UIKit.h>
#import "DSPRuntimeBrowserToolbar.h"
#import "DSPMethod.h"

@protocol DSPKeyPathSearchControllerDelegate <UITableViewDataSource>

@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, readonly) UISearchController *searchController;

/// For loaded images which don't have an NSBundle
- (void)didSelectImagePath:(NSString *)message shortName:(NSString *)shortName;
- (void)didSelectBundle:(NSBundle *)bundle;
- (void)didSelectClass:(Class)cls;

@end


@interface DSPKeyPathSearchController : NSObject <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

+ (instancetype)delegate:(id<DSPKeyPathSearchControllerDelegate>)delegate;

@property (nonatomic) DSPRuntimeBrowserToolbar *toolbar;

/// Suggestions for the toolbar
@property (nonatomic, readonly) NSArray<NSString *> *suggestions;

- (void)didSelectKeyPathOption:(NSString *)text;
- (void)didPressButton:(NSString *)text insertInto:(UISearchBar *)searchBar;

@end
