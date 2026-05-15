#import "DSPTableListViewController.h"
#import "DSPDatabaseManager.h"
#import "DSPSQLiteDatabaseManager.h"
#import "DSPRealmDatabaseManager.h"
#import "DSPTableContentViewController.h"
#import "DSPMutableListSection.h"
#import "NSArray+DSP.h"
#import "DSPAlert.h"
#import "DSPMacros.h"

@interface DSPTableListViewController ()
@property (nonatomic, readonly) id<DSPDatabaseManager> dbm;
@property (nonatomic, readonly) NSString *path;

@property (nonatomic, readonly) DSPMutableListSection<NSString *> *tables;

+ (NSArray<NSString *> *)supportedSQLiteExtensions;
+ (NSArray<NSString *> *)supportedRealmExtensions;

@end

@implementation DSPTableListViewController

- (instancetype)initWithPath:(NSString *)path {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        _path = path.copy;
        _dbm = [self databaseManagerForFileAtPath:path];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.showsSearchBar = YES;
    
    // Compose query button //

    UIBarButtonItem *composeQuery = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
        target:self
        action:@selector(queryButtonPressed)
    ];
    // Cannot run custom queries on realm databases
    composeQuery.enabled = [self.dbm
        respondsToSelector:@selector(executeStatement:)
    ];
    
    [self addToolbarItems:@[composeQuery]];
}

- (NSArray<DSPTableViewSection *> *)makeSections {
    _tables = [DSPMutableListSection list:[self.dbm queryAllTables]
        cellConfiguration:^(__kindof UITableViewCell *cell, NSString *tableName, NSInteger row) {
            cell.textLabel.text = tableName;
        } filterMatcher:^BOOL(NSString *filterText, NSString *tableName) {
            return [tableName localizedCaseInsensitiveContainsString:filterText];
        }
    ];
    
    self.tables.selectionHandler = ^(DSPTableListViewController *host, NSString *tableName) {
        NSArray *rows = [host.dbm queryAllDataInTable:tableName];
        NSArray *columns = [host.dbm queryAllColumnsOfTable:tableName];
        NSArray *rowIDs = nil;
        if ([host.dbm respondsToSelector:@selector(queryRowIDsInTable:)]) {        
            rowIDs = [host.dbm queryRowIDsInTable:tableName];
        }
        UIViewController *resultsScreen = [DSPTableContentViewController
            columns:columns rows:rows rowIDs:rowIDs tableName:tableName database:host.dbm
        ];
        [host.navigationController pushViewController:resultsScreen animated:YES];
    };
    
    return @[self.tables];
}

- (void)reloadData {
    self.tables.customTitle = [NSString
        stringWithFormat:@"Tables (%@)", @(self.tables.filteredList.count)
    ];
    
    [super reloadData];
}
    
- (void)queryButtonPressed {
    DSPSQLiteDatabaseManager *database = self.dbm;
    
    [DSPAlert makeAlert:^(DSPAlert *make) {
        make.title(@"Execute an SQL query");
        make.textField(nil);
        make.button(@"Run").handler(^(NSArray<NSString *> *strings) {
            DSPSQLResult *result = [database executeStatement:strings[0]];
            
            if (result.message) {
                [DSPAlert showAlert:@"Message" message:result.message from:self];
            } else {
                UIViewController *resultsScreen = [DSPTableContentViewController
                    columns:result.columns rows:result.rows
                ];
                
                [self.navigationController pushViewController:resultsScreen animated:YES];
            }
        });
        make.button(@"Cancel").cancelStyle();
    } showFrom:self];
}
    
- (id<DSPDatabaseManager>)databaseManagerForFileAtPath:(NSString *)path {
    NSString *pathExtension = path.pathExtension.lowercaseString;
    
    NSArray<NSString *> *sqliteExtensions = DSPTableListViewController.supportedSQLiteExtensions;
    if ([sqliteExtensions indexOfObject:pathExtension] != NSNotFound) {
        return [DSPSQLiteDatabaseManager managerForDatabase:path];
    }
    
    NSArray<NSString *> *realmExtensions = DSPTableListViewController.supportedRealmExtensions;
    if (realmExtensions != nil && [realmExtensions indexOfObject:pathExtension] != NSNotFound) {
        return [DSPRealmDatabaseManager managerForDatabase:path];
    }
    
    return nil;
}


#pragma mark - DSPTableListViewController

+ (BOOL)supportsExtension:(NSString *)extension {
    extension = extension.lowercaseString;
    
    NSArray<NSString *> *sqliteExtensions = DSPTableListViewController.supportedSQLiteExtensions;
    if (sqliteExtensions.count > 0 && [sqliteExtensions indexOfObject:extension] != NSNotFound) {
        return YES;
    }
    
    NSArray<NSString *> *realmExtensions = DSPTableListViewController.supportedRealmExtensions;
    if (realmExtensions.count > 0 && [realmExtensions indexOfObject:extension] != NSNotFound) {
        return YES;
    }
    
    return NO;
}

+ (NSArray<NSString *> *)supportedSQLiteExtensions {
    return @[@"db", @"sqlite", @"sqlite3"];
}

+ (NSArray<NSString *> *)supportedRealmExtensions {
    if (NSClassFromString(@"RLMRealm") == nil) {
        return nil;
    }
    
    return @[@"realm"];
}

@end
