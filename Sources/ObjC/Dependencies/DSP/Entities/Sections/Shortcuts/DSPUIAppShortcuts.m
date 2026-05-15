#import "DSPUIAppShortcuts.h"
#import "DSPRuntimeUtility.h"
#import "DSPShortcut.h"
#import "DSPAlert.h"

@implementation DSPUIAppShortcuts

#pragma mark - Overrides

+ (instancetype)forObject:(UIApplication *)application {
    return [self forObject:application additionalRows:@[
        [DSPActionShortcut title:@"Open URL…"
            subtitle:^NSString *(UIViewController *controller) {
                return nil;
            }
            selectionHandler:^void(UIViewController *host, UIApplication *app) {
                [DSPAlert makeAlert:^(DSPAlert *make) {
                    make.title(@"Open URL");
                    make.message(
                        @"This will call openURL: or openURL:options:completion: "
                         "with the string below. 'Open if Universal' will only open "
                         "the URL if it is a registered Universal Link."
                    );
                    
                    make.textField(@"twitter://user?id=12345");
                    make.button(@"Open").handler(^(NSArray<NSString *> *strings) {
                        [self openURL:strings[0] inApp:app onlyIfUniveral:NO host:host];
                    });
                    make.button(@"Open if Universal").handler(^(NSArray<NSString *> *strings) {
                        [self openURL:strings[0] inApp:app onlyIfUniveral:YES host:host];
                    });
                    make.button(@"Cancel").cancelStyle();
                } showFrom:host];
            }
            accessoryType:^UITableViewCellAccessoryType(UIViewController *controller) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ]
    ]];
}

+ (void)openURL:(NSString *)urlString
          inApp:(UIApplication *)app
 onlyIfUniveral:(BOOL)universalOnly
           host:(UIViewController *)host {
    NSURL *url = [NSURL URLWithString:urlString];
    
    if (url) {
        if (@available(iOS 10, *)) {
            [app openURL:url options:@{
                UIApplicationOpenURLOptionUniversalLinksOnly: @(universalOnly)
            } completionHandler:^(BOOL success) {
                if (!success) {
                    [DSPAlert showAlert:@"No Universal Link Handler"
                        message:@"No installed application is registered to handle this link."
                        from:host
                    ];
                }
            }];
        } else {
            [app openURL:url];
        }
    } else {
        [DSPAlert showAlert:@"Error" message:@"Invalid URL" from:host];
    }
}

@end

