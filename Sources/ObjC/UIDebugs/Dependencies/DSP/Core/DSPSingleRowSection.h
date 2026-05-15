#import "DSPTableViewSection.h"

NS_ASSUME_NONNULL_BEGIN

/// A section providing a specific single row.
///
/// You may optionally provide a view controller to push when the row
/// is selected, or an action to perform when it is selected.
/// Which one is used first is up to the table view data source.
@interface DSPSingleRowSection : DSPTableViewSection

/// @param reuseIdentifier if nil, kDSPDefaultCell is used.
+ (instancetype)title:(nullable NSString *)sectionTitle
                reuse:(nullable NSString *)reuseIdentifier
                 cell:(void(^)(__kindof UITableViewCell *cell))cellConfiguration;

@property (nullable, nonatomic) UIViewController *pushOnSelection;
@property (nullable, nonatomic) void (^selectionAction)(UIViewController *host);
/// Called to determine whether the single row should display itself or not.
@property (nonatomic) BOOL (^filterMatcher)(NSString *filterText);

@end

NS_ASSUME_NONNULL_END
