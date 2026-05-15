#import "DSPNSStringShortcuts.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPShortcut.h"

@implementation DSPNSStringShortcuts

+ (instancetype)forObject:(NSString *)string {
    NSUInteger length = [string lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytesNoCopy:(void *)string.UTF8String length:length freeWhenDone:NO];
    
    return [self forObject:string additionalRows:@[
        [DSPActionShortcut title:@"UTF-8 Data" subtitle:^NSString *(id _) {
            return data.description;
        } viewer:^UIViewController *(id _) {
            return [DSPObjectExplorerFactory explorerViewControllerForObject:data];
        } accessoryType:^UITableViewCellAccessoryType(id _) {
            return UITableViewCellAccessoryDisclosureIndicator;
        }]
    ]];
}

@end
