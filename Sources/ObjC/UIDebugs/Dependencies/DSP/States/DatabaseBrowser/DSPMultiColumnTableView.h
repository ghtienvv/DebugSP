#import <UIKit/UIKit.h>
#import "DSPTableColumnHeader.h"

@class DSPMultiColumnTableView;

@protocol DSPMultiColumnTableViewDelegate <NSObject>

@required
- (void)multiColumnTableView:(DSPMultiColumnTableView *)tableView didSelectRow:(NSInteger)row;
- (void)multiColumnTableView:(DSPMultiColumnTableView *)tableView didSelectHeaderForColumn:(NSInteger)column sortType:(DSPTableColumnHeaderSortType)sortType;

@end

@protocol DSPMultiColumnTableViewDataSource <NSObject>

@required

- (NSInteger)numberOfColumnsInTableView:(DSPMultiColumnTableView *)tableView;
- (NSInteger)numberOfRowsInTableView:(DSPMultiColumnTableView *)tableView;
- (NSString *)columnTitle:(NSInteger)column;
- (NSString *)rowTitle:(NSInteger)row;
- (NSArray<NSString *> *)contentForRow:(NSInteger)row;

- (CGFloat)multiColumnTableView:(DSPMultiColumnTableView *)tableView minWidthForContentCellInColumn:(NSInteger)column;
- (CGFloat)multiColumnTableView:(DSPMultiColumnTableView *)tableView heightForContentCellInRow:(NSInteger)row;
- (CGFloat)heightForTopHeaderInTableView:(DSPMultiColumnTableView *)tableView;
- (CGFloat)widthForLeftHeaderInTableView:(DSPMultiColumnTableView *)tableView;

@end


@interface DSPMultiColumnTableView : UIView

@property (nonatomic, weak) id<DSPMultiColumnTableViewDataSource> dataSource;
@property (nonatomic, weak) id<DSPMultiColumnTableViewDelegate> delegate;

- (void)reloadData;

@end
