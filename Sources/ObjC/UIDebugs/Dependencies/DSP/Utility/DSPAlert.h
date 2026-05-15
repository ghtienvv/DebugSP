#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DSPAlert, DSPAlertAction;

typedef void (^DSPAlertReveal)(void);
typedef void (^DSPAlertBuilder)(DSPAlert *make);
typedef DSPAlert * _Nonnull (^DSPAlertStringProperty)(NSString * _Nullable);
typedef DSPAlert * _Nonnull (^DSPAlertStringArg)(NSString * _Nullable);
typedef DSPAlert * _Nonnull (^DSPAlertTextField)(void(^configurationHandler)(UITextField *textField));
typedef DSPAlertAction * _Nonnull (^DSPAlertAddAction)(NSString *title);
typedef DSPAlertAction * _Nonnull (^DSPAlertActionStringProperty)(NSString * _Nullable);
typedef DSPAlertAction * _Nonnull (^DSPAlertActionProperty)(void);
typedef DSPAlertAction * _Nonnull (^DSPAlertActionBOOLProperty)(BOOL);
typedef DSPAlertAction * _Nonnull (^DSPAlertActionHandler)(void(^handler)(NSArray<NSString *> *strings));

@interface DSPAlert : NSObject

/// Shows a simple alert with one button which says "Dismiss"
+ (void)showAlert:(NSString * _Nullable)title message:(NSString * _Nullable)message from:(UIViewController *)viewController;

/// Shows a simple alert with no buttons and only a title, for half a second
+ (void)showQuickAlert:(NSString *)title from:(UIViewController *)viewController;

/// Construct and display an alert
+ (void)makeAlert:(DSPAlertBuilder)block showFrom:(UIViewController *)viewController;
/// Construct and display an action sheet-style alert
+ (void)makeSheet:(DSPAlertBuilder)block
         showFrom:(UIViewController *)viewController
           source:(nullable id)viewOrBarItem;

/// Construct an alert
+ (UIAlertController *)makeAlert:(DSPAlertBuilder)block;
/// Construct an action sheet-style alert
+ (UIAlertController *)makeSheet:(DSPAlertBuilder)block;

/// Set the alert's title.
///
/// Call in succession to append strings to the title.
@property (nonatomic, readonly) DSPAlertStringProperty title;
/// Set the alert's message.
///
/// Call in succession to append strings to the message.
@property (nonatomic, readonly) DSPAlertStringProperty message;
/// Add a button with a given title with the default style and no action.
@property (nonatomic, readonly) DSPAlertAddAction button;
/// Add a text field with the given (optional) placeholder text.
@property (nonatomic, readonly) DSPAlertStringArg textField;
/// Add and configure the given text field.
///
/// Use this if you need to more than set the placeholder, such as
/// supply a delegate, make it secure entry, or change other attributes.
@property (nonatomic, readonly) DSPAlertTextField configuredTextField;

@end

@interface DSPAlertAction : NSObject

/// Set the action's title.
///
/// Call in succession to append strings to the title.
@property (nonatomic, readonly) DSPAlertActionStringProperty title;
/// Make the action destructive. It appears with red text.
@property (nonatomic, readonly) DSPAlertActionProperty destructiveStyle;
/// Make the action cancel-style. It appears with a bolder font.
@property (nonatomic, readonly) DSPAlertActionProperty cancelStyle;
/// Enable or disable the action. Enabled by default.
@property (nonatomic, readonly) DSPAlertActionBOOLProperty enabled;
/// Give the button an action. The action takes an array of text field strings.
@property (nonatomic, readonly) DSPAlertActionHandler handler;
/// Access the underlying UIAlertAction, should you need to change it while
/// the encompassing alert is being displayed. For example, you may want to
/// enable or disable a button based on the input of some text fields in the alert.
/// Do not call this more than once per instance.
@property (nonatomic, readonly) UIAlertAction *action;

@end

NS_ASSUME_NONNULL_END
