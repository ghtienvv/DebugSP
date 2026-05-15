#import <UIKit/UIKit.h>
#import "DSPDatabaseManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface DSPTableContentViewController : UIViewController

/// Display a mutable table with the given columns, rows, and name.
///
/// @param columnNames self explanatory.
/// @param rowData an array of rows, where each row is an array of column data.
/// @param rowIDs an array of stringy row IDs. Required for deleting rows.
/// @param tableName an optional name of the table being viewed, if any. Enables adding rows.
/// @param databaseManager an optional manager to allow modifying the table.
///        Required for deleting rows. Required for adding rows if \c tableName is supplied.
+ (instancetype)columns:(NSArray<NSString *> *)columnNames
                   rows:(NSArray<NSArray<NSString *> *> *)rowData
                 rowIDs:(NSArray<NSString *> *)rowIDs
              tableName:(NSString *)tableName
               database:(id<DSPDatabaseManager>)databaseManager;

/// Display an immutable table with the given columns and rows.
+ (instancetype)columns:(NSArray<NSString *> *)columnNames
                   rows:(NSArray<NSArray<NSString *> *> *)rowData;

@end

NS_ASSUME_NONNULL_END
