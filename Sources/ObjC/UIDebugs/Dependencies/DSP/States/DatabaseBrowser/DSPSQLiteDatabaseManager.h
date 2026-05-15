#import <Foundation/Foundation.h>
#import "DSPDatabaseManager.h"
#import "DSPSQLResult.h"

@interface DSPSQLiteDatabaseManager : NSObject <DSPDatabaseManager>

/// Contains the result of the last operation, which may be an error
@property (nonatomic, readonly) DSPSQLResult *lastResult;
/// Calls into \c sqlite3_last_insert_rowid()
@property (nonatomic, readonly) NSInteger lastRowID;

/// Given a statement like 'SELECT * from @table where @col = @val' and arguments
/// like { @"table": @"Album", @"col": @"year", @"val" @1 } this method will
/// invoke the statement and properly bind the given arguments to the statement.
///
/// You may pass NSStrings, NSData, NSNumbers, or NSNulls as values.
- (DSPSQLResult *)executeStatement:(NSString *)statement arguments:(NSDictionary<NSString *, id> *)args;

@end
