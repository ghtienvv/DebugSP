#import <UIKit/UIKit.h>

typedef void (^DSPKBToolbarAction)(NSString *buttonTitle, BOOL isSuggestion);


@interface DSPKBToolbarButton : UIButton

/// Set to `default` to use the system appearance on iOS 13+
@property (nonatomic) UIKeyboardAppearance appearance;

+ (instancetype)buttonWithTitle:(NSString *)title;
+ (instancetype)buttonWithTitle:(NSString *)title action:(DSPKBToolbarAction)eventHandler;
+ (instancetype)buttonWithTitle:(NSString *)title action:(DSPKBToolbarAction)action forControlEvents:(UIControlEvents)controlEvents;

/// Adds the event handler for the button.
///
/// @param eventHandler The event handler block.
/// @param controlEvents The type of event.
- (void)addEventHandler:(DSPKBToolbarAction)eventHandler forControlEvents:(UIControlEvents)controlEvents;

@end

@interface DSPKBToolbarSuggestedButton : DSPKBToolbarButton @end
