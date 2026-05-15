#import "DSPColorPreviewSection.h"

@implementation DSPColorPreviewSection

+ (instancetype)forObject:(UIColor *)color {
    return [self title:@"Color" reuse:nil cell:^(__kindof UITableViewCell *cell) {
        cell.backgroundColor = color;
    }];
}

- (BOOL)canSelectRow:(NSInteger)row {
    return NO;
}

- (BOOL (^)(NSString *))filterMatcher {
    return ^BOOL(NSString *filterText) {
        // Hide when searching
        return !filterText.length;
    };
}

@end
