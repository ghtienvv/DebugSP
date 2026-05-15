#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark Reuse identifiers

typedef NSString * DSPTableViewCellReuseIdentifier;
typedef DSPTableViewCellReuseIdentifier DSPTableViewCellReuseIdentifier;

/// A regular \c DSPTableViewCell initialized with \c UITableViewCellStyleDefault
extern DSPTableViewCellReuseIdentifier const kDSPDefaultCell;
/// A \c DSPSubtitleTableViewCell initialized with \c UITableViewCellStyleSubtitle
extern DSPTableViewCellReuseIdentifier const kDSPDetailCell;
/// A \c DSPMultilineTableViewCell initialized with \c UITableViewCellStyleDefault
extern DSPTableViewCellReuseIdentifier const kDSPMultilineCell;
/// A \c DSPMultilineTableViewCell initialized with \c UITableViewCellStyleSubtitle
extern DSPTableViewCellReuseIdentifier const kDSPMultilineDetailCell;
/// A \c DSPTableViewCell initialized with \c UITableViewCellStyleValue1
extern DSPTableViewCellReuseIdentifier const kDSPKeyValueCell;
/// A \c DSPSubtitleTableViewCell which uses monospaced fonts for both labels
extern DSPTableViewCellReuseIdentifier const kDSPCodeFontCell;

#pragma mark - DSPTableView
@interface DSPTableView : UITableView

+ (instancetype)dspDefaultTableView;
+ (instancetype)groupedTableView;
+ (instancetype)plainTableView;
+ (instancetype)style:(UITableViewStyle)style;

/// You do not need to register classes for any of the default reuse identifiers above
/// (annotated as \c DSPTableViewCellReuseIdentifier types) unless you wish to provide
/// a custom cell for any of those reuse identifiers. By default, \c DSPTableViewCell,
/// \c DSPSubtitleTableViewCell, and \c DSPMultilineTableViewCell are used, respectively.
///
/// @param registrationMapping A map of reuse identifiers to \c UITableViewCell (sub)class objects.
- (void)registerCells:(NSDictionary<NSString *, Class> *)registrationMapping;

@end

NS_ASSUME_NONNULL_END
