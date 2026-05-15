#import <Foundation/Foundation.h>
#import "DSPSQLResult.h"

/// Conformers should automatically open and close the database
@protocol DSPDatabaseManager <NSObject>

@required

/// @return \c nil if the database couldn't be opened
+ (instancetype)managerForDatabase:(NSString *)path;

/// @return a list of all table names
- (NSArray<NSString *> *)queryAllTables;
- (NSArray<NSString *> *)queryAllColumnsOfTable:(NSString *)tableName;
- (NSArray<NSArray *> *)queryAllDataInTable:(NSString *)tableName;

@optional

- (NSArray<NSString *> *)queryRowIDsInTable:(NSString *)tableName;
- (DSPSQLResult *)executeStatement:(NSString *)SQLStatement;

@end
