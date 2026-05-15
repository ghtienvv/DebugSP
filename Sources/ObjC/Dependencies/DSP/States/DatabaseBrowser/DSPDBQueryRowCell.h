#import <UIKit/UIKit.h>

@class DSPDBQueryRowCell;

extern NSString * const kDSPDBQueryRowCellReuseIdentifier;
// Compatibility alias for older source references.
extern NSString * const kDSPDBQueryRowCellReuse;

@protocol DSPDBQueryRowCellLayoutSource <NSObject>

- (CGFloat)dbQueryRowCell:(DSPDBQueryRowCell *)dbQueryRowCell minXForColumn:(NSUInteger)column;
- (CGFloat)dbQueryRowCell:(DSPDBQueryRowCell *)dbQueryRowCell widthForColumn:(NSUInteger)column;

@end

@interface DSPDBQueryRowCell : UITableViewCell

/// An array of NSString, NSNumber, or NSData objects
@property (nonatomic) NSArray *data;
@property (nonatomic, weak) id<DSPDBQueryRowCellLayoutSource> layoutSource;

@end
