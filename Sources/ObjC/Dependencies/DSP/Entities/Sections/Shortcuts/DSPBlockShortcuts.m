#import "DSPBlockShortcuts.h"
#import "DSPShortcut.h"
#import "DSPBlockDescription.h"
#import "DSPObjectExplorerFactory.h"

#pragma mark - 
@implementation DSPBlockShortcuts

#pragma mark Overrides

+ (instancetype)forObject:(id)block {
    NSParameterAssert([block isKindOfClass:NSClassFromString(@"NSBlock")]);
    
    DSPBlockDescription *blockInfo = [DSPBlockDescription describing:block];
    NSMethodSignature *signature = blockInfo.signature;
    NSArray *blockShortcutRows = @[blockInfo.summary];
    
    if (signature) {
        blockShortcutRows = @[
            blockInfo.summary,
            blockInfo.sourceDeclaration,
            signature.debugDescription,
            [DSPActionShortcut title:@"View Method Signature"
                subtitle:^NSString *(id block) {
                    return signature.description ?: @"unsupported signature";
                }
                viewer:^UIViewController *(id block) {
                    return [DSPObjectExplorerFactory explorerViewControllerForObject:signature];
                }
                accessoryType:^UITableViewCellAccessoryType(id view) {
                    if (signature) {
                        return UITableViewCellAccessoryDisclosureIndicator;
                    }
                    return UITableViewCellAccessoryNone;
                }
            ]
        ];
    }
    
    return [self forObject:block additionalRows:blockShortcutRows];
}

- (NSString *)title {
    return @"Metadata";
}

- (NSInteger)numberOfLines {
    return 0;
}

@end
