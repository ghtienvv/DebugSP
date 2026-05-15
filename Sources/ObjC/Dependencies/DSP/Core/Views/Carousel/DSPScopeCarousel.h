#import <UIKit/UIKit.h>

/// Only use on iOS 10 and up. Requires iOS 10 APIs for calculating row sizes.
@interface DSPScopeCarousel : UIControl

@property (nonatomic, copy) NSArray<NSString *> *items;
@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic) void(^selectedIndexChangedAction)(NSInteger idx);

- (void)registerBlockForDynamicTypeChanges:(void(^)(DSPScopeCarousel *))handler;

@end
