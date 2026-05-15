#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DSPTableColumnHeaderSortType) {
    DSPTableColumnHeaderSortTypeNone = 0,
    DSPTableColumnHeaderSortTypeAsc,
    DSPTableColumnHeaderSortTypeDesc,
};

NS_INLINE DSPTableColumnHeaderSortType DSPNextTableColumnHeaderSortType(
    DSPTableColumnHeaderSortType current) {
    switch (current) {
        case DSPTableColumnHeaderSortTypeAsc:
            return DSPTableColumnHeaderSortTypeDesc;
        case DSPTableColumnHeaderSortTypeNone:
        case DSPTableColumnHeaderSortTypeDesc:
            return DSPTableColumnHeaderSortTypeAsc;
    }
    
    return DSPTableColumnHeaderSortTypeNone;
}

@interface DSPTableColumnHeader : UIView

@property (nonatomic) NSInteger index;
@property (nonatomic, readonly) UILabel *titleLabel;

@property (nonatomic) DSPTableColumnHeaderSortType sortType;

@end

