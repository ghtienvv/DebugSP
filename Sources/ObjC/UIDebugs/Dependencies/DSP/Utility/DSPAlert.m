#import "DSPAlert.h"
#import "DSPMacros.h"

@interface DSPAlert ()
@property (nonatomic, readonly) UIAlertController *_controller;
@property (nonatomic, readonly) NSMutableArray<DSPAlertAction *> *_actions;
@end

#define DSPAlertActionMutationAssertion() \
NSAssert(!self._action, @"Cannot mutate action after retreiving underlying UIAlertAction");

@interface DSPAlertAction ()
@property (nonatomic) UIAlertController *_controller;
@property (nonatomic) NSString *_title;
@property (nonatomic) UIAlertActionStyle _style;
@property (nonatomic) BOOL _disable;
@property (nonatomic) void(^_handler)(UIAlertAction *action);
@property (nonatomic) UIAlertAction *_action;
@end

@implementation DSPAlert

+ (void)showAlert:(NSString *)title message:(NSString *)message from:(UIViewController *)viewController {
    [self makeAlert:^(DSPAlert *make) {
        make.title(title).message(message).button(@"Dismiss").cancelStyle();
    } showFrom:viewController];
}

+ (void)showQuickAlert:(NSString *)title from:(UIViewController *)viewController {
    UIAlertController *alert = [self makeAlert:^(DSPAlert *make) {
        make.title(title);
    }];
    
    [viewController presentViewController:alert animated:YES completion:^{
        dsp_dispatch_after(0.5, dispatch_get_main_queue(), ^{
            [alert dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

#pragma mark Initialization

- (instancetype)initWithController:(UIAlertController *)controller {
    self = [super init];
    if (self) {
        __controller = controller;
        __actions = [NSMutableArray new];
    }

    return self;
}

+ (UIAlertController *)make:(DSPAlertBuilder)block withStyle:(UIAlertControllerStyle)style {
    // Create alert builder
    DSPAlert *alert = [[self alloc] initWithController:
        [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:style]
    ];

    // Configure alert
    block(alert);

    // Add actions
    for (DSPAlertAction *builder in alert._actions) {
        [alert._controller addAction:builder.action];
    }

    return alert._controller;
}

+ (void)make:(DSPAlertBuilder)block
   withStyle:(UIAlertControllerStyle)style
    showFrom:(UIViewController *)viewController
      source:(id)viewOrBarItem {
    UIAlertController *alert = [self make:block withStyle:style];
    if ([viewOrBarItem isKindOfClass:[UIBarButtonItem class]]) {
        alert.popoverPresentationController.barButtonItem = viewOrBarItem;
    } else if ([viewOrBarItem isKindOfClass:[UIView class]]) {
        alert.popoverPresentationController.sourceView = viewOrBarItem;
        alert.popoverPresentationController.sourceRect = [viewOrBarItem bounds];
    } else if (viewOrBarItem) {
        NSParameterAssert(
            [viewOrBarItem isKindOfClass:[UIBarButtonItem class]] ||
            [viewOrBarItem isKindOfClass:[UIView class]] ||
            !viewOrBarItem
        );
    }
    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (void)makeAlert:(DSPAlertBuilder)block showFrom:(UIViewController *)controller {
    [self make:block withStyle:UIAlertControllerStyleAlert showFrom:controller source:nil];
}

+ (void)makeSheet:(DSPAlertBuilder)block showFrom:(UIViewController *)controller {
    [self make:block withStyle:UIAlertControllerStyleActionSheet showFrom:controller source:nil];
}

/// Construct and display an action sheet-style alert
+ (void)makeSheet:(DSPAlertBuilder)block
         showFrom:(UIViewController *)controller
           source:(id)viewOrBarItem {
    [self make:block
     withStyle:UIAlertControllerStyleActionSheet
      showFrom:controller
        source:viewOrBarItem];
}

+ (UIAlertController *)makeAlert:(DSPAlertBuilder)block {
    return [self make:block withStyle:UIAlertControllerStyleAlert];
}

+ (UIAlertController *)makeSheet:(DSPAlertBuilder)block {
    return [self make:block withStyle:UIAlertControllerStyleActionSheet];
}

#pragma mark Configuration

- (DSPAlertStringProperty)title {
    return ^DSPAlert *(NSString *title) {
        if (self._controller.title) {
            self._controller.title = [self._controller.title stringByAppendingString:title ?: @""];
        } else {
            self._controller.title = title;
        }
        return self;
    };
}

- (DSPAlertStringProperty)message {
    return ^DSPAlert *(NSString *message) {
        if (self._controller.message) {
            self._controller.message = [self._controller.message stringByAppendingString:message ?: @""];
        } else {
            self._controller.message = message;
        }
        return self;
    };
}

- (DSPAlertAddAction)button {
    return ^DSPAlertAction *(NSString *title) {
        DSPAlertAction *action = DSPAlertAction.new.title(title);
        action._controller = self._controller;
        [self._actions addObject:action];
        return action;
    };
}

- (DSPAlertStringArg)textField {
    return ^DSPAlert *(NSString *placeholder) {
        [self._controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = placeholder;
        }];

        return self;
    };
}

- (DSPAlertTextField)configuredTextField {
    return ^DSPAlert *(void(^configurationHandler)(UITextField *)) {
        [self._controller addTextFieldWithConfigurationHandler:configurationHandler];
        return self;
    };
}

@end

@implementation DSPAlertAction

- (DSPAlertActionStringProperty)title {
    return ^DSPAlertAction *(NSString *title) {
        DSPAlertActionMutationAssertion();
        if (self._title) {
            self._title = [self._title stringByAppendingString:title ?: @""];
        } else {
            self._title = title;
        }
        return self;
    };
}

- (DSPAlertActionProperty)destructiveStyle {
    return ^DSPAlertAction *() {
        DSPAlertActionMutationAssertion();
        self._style = UIAlertActionStyleDestructive;
        return self;
    };
}

- (DSPAlertActionProperty)cancelStyle {
    return ^DSPAlertAction *() {
        DSPAlertActionMutationAssertion();
        self._style = UIAlertActionStyleCancel;
        return self;
    };
}

- (DSPAlertActionBOOLProperty)enabled {
    return ^DSPAlertAction *(BOOL enabled) {
        DSPAlertActionMutationAssertion();
        self._disable = !enabled;
        return self;
    };
}

- (DSPAlertActionHandler)handler {
    return ^DSPAlertAction *(void(^handler)(NSArray<NSString *> *)) {
        DSPAlertActionMutationAssertion();

        // Get weak reference to the alert to avoid block <--> alert retain cycle
        UIAlertController *controller = self._controller; weakify(controller)
        self._handler = ^(UIAlertAction *action) { strongify(controller)
            // Strongify that reference and pass the text field strings to the handler
            NSArray *strings = [controller.textFields valueForKeyPath:@"text"];
            handler(strings);
        };

        return self;
    };
}

- (UIAlertAction *)action {
    if (self._action) {
        return self._action;
    }

    self._action = [UIAlertAction
        actionWithTitle:self._title
        style:self._style
        handler:self._handler
    ];
    self._action.enabled = !self._disable;

    return self._action;
}

@end
