#import "DSPSQLResult.h"
#import "NSArray+DSP.h"

@implementation DSPSQLResult
@synthesize keyedRows = _keyedRows;

+ (instancetype)message:(NSString *)message {
    return [[self alloc] initWithMessage:message columns:nil rows:nil];
}

+ (instancetype)error:(NSString *)message {
    DSPSQLResult *result = [self message:message];
    result->_isError = YES;
    return result;
}

+ (instancetype)columns:(NSArray<NSString *> *)columnNames rows:(NSArray<NSArray<NSString *> *> *)rowData {
    return [[self alloc] initWithMessage:nil columns:columnNames rows:rowData];
}

- (instancetype)initWithMessage:(NSString *)message columns:(NSArray<NSString *> *)columns rows:(NSArray<NSArray<NSString *> *> *)rows {
    NSParameterAssert(message || (columns && rows));
    NSParameterAssert(rows.count == 0 || columns.count == rows.firstObject.count);
    
    self = [super init];
    if (self) {
        _message = message;
        _columns = columns;
        _rows = rows;
    }
    
    return self;
}

- (NSArray<NSDictionary<NSString *,id> *> *)keyedRows {
    if (!_keyedRows) {
        _keyedRows = [self.rows dsp_mapped:^id(NSArray<NSString *> *row, NSUInteger idx) {
            return [NSDictionary dictionaryWithObjects:row forKeys:self.columns];
        }];
    }
    
    return _keyedRows;
}

@end
