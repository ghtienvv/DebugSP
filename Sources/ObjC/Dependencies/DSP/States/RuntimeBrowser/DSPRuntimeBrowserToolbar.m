#import "DSPRuntimeBrowserToolbar.h"
#import "DSPRuntimeKeyPathTokenizer.h"

@interface DSPRuntimeBrowserToolbar ()
@property (nonatomic, copy) DSPKBToolbarAction tapHandler;
@end

@implementation DSPRuntimeBrowserToolbar

+ (instancetype)toolbarWithHandler:(DSPKBToolbarAction)tapHandler suggestions:(NSArray<NSString *> *)suggestions {
    NSArray *buttons = [self
        buttonsForKeyPath:DSPRuntimeKeyPath.empty suggestions:suggestions handler:tapHandler
    ];

    DSPRuntimeBrowserToolbar *me = [self toolbarWithButtons:buttons];
    me.tapHandler = tapHandler;
    return me;
}

+ (NSArray<DSPKBToolbarButton*> *)buttonsForKeyPath:(DSPRuntimeKeyPath *)keyPath
                                     suggestions:(NSArray<NSString *> *)suggestions
                                         handler:(DSPKBToolbarAction)handler {
    NSMutableArray *buttons = [NSMutableArray new];
    DSPSearchToken *lastKey = nil;
    BOOL lastKeyIsMethod = NO;

    if (keyPath.methodKey) {
        lastKey = keyPath.methodKey;
        lastKeyIsMethod = YES;
    } else {
        lastKey = keyPath.classKey ?: keyPath.bundleKey;
    }

    switch (lastKey.options) {
        case TBWildcardOptionsNone:
        case TBWildcardOptionsAny:
            if (lastKeyIsMethod) {
                if (!keyPath.instanceMethods) {
                    [buttons addObject:[DSPKBToolbarButton buttonWithTitle:@"-" action:handler]];
                    [buttons addObject:[DSPKBToolbarButton buttonWithTitle:@"+" action:handler]];
                }
                [buttons addObject:[DSPKBToolbarButton buttonWithTitle:@"*" action:handler]];
            } else {
                [buttons addObject:[DSPKBToolbarButton buttonWithTitle:@"*" action:handler]];
                [buttons addObject:[DSPKBToolbarButton buttonWithTitle:@"*." action:handler]];
            }
            break;

        default: {
            if (lastKey.options & TBWildcardOptionsPrefix) {
                if (lastKeyIsMethod) {
                    if (lastKey.string.length) {
                        [buttons addObject:[DSPKBToolbarButton buttonWithTitle:@"*" action:handler]];
                    }
                } else {
                    if (lastKey.string.length) {
                        [buttons addObject:[DSPKBToolbarButton buttonWithTitle:@"*." action:handler]];
                    }
                }
            }

            else if (lastKey.options & TBWildcardOptionsSuffix) {
                if (!lastKeyIsMethod) {
                    [buttons addObject:[DSPKBToolbarButton buttonWithTitle:@"*" action:handler]];
                    [buttons addObject:[DSPKBToolbarButton buttonWithTitle:@"*." action:handler]];
                }
            }
        }
    }
    
    for (NSString *suggestion in suggestions) {
        [buttons addObject:[DSPKBToolbarSuggestedButton buttonWithTitle:suggestion action:handler]];
    }

    return buttons;
}

- (void)setKeyPath:(DSPRuntimeKeyPath *)keyPath suggestions:(NSArray<NSString *> *)suggestions {
    self.buttons = [self.class
        buttonsForKeyPath:keyPath suggestions:suggestions handler:self.tapHandler
    ];
}

@end
