#import <UIKit/UIKit.h>

@interface DSPHierarchyTableViewCell : UITableViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier;

@property (nonatomic) NSInteger viewDepth;
@property (nonatomic) UIColor *randomColorTag;
@property (nonatomic) UIColor *indicatedViewColor;

@end
