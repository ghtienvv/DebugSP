#import "DSPNSDataShortcuts.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPShortcut.h"

@implementation DSPNSDataShortcuts

+ (instancetype)forObject:(NSData *)data {
    NSString *string = [self stringForData:data];
    
    return [self forObject:data additionalRows:@[
        [DSPActionShortcut title:@"UTF-8 String" subtitle:^(NSData *object) {
            return string.length ? string : (string ?
                @"Data is not a UTF8 String" : @"Empty string"
            );
        } viewer:^UIViewController *(id object) {
            return [DSPObjectExplorerFactory explorerViewControllerForObject:string];
        } accessoryType:^UITableViewCellAccessoryType(NSData *object) {
            if (string.length) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
            
            return UITableViewCellAccessoryNone;
        }]
    ]];
}

+ (NSString *)stringForData:(NSData *)data {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end

@interface NSData (Overrides) @end
@implementation NSData (Overrides)

// This normally crashes
- (NSUInteger)length {
    return 0;
}

@end
