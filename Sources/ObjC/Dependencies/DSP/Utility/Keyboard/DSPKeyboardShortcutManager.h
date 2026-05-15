#import <UIKit/UIKit.h>

@interface DSPKeyboardShortcutManager : NSObject

@property (nonatomic, readonly, class) DSPKeyboardShortcutManager *sharedManager;

/// @param key A single character string matching a key on the keyboard
/// @param modifiers Modifier keys such as shift, command, or alt/option
/// @param action The block to run on the main thread when the key & modifier combination is recognized.
/// @param description Shown the the keyboard shortcut help menu, which is accessed via the '?' key.
/// @param allowOverride Allow registering even if there's an existing action associated with that key/modifier.
- (void)registerSimulatorShortcutWithKey:(NSString *)key
                               modifiers:(UIKeyModifierFlags)modifiers
                                  action:(dispatch_block_t)action
                             description:(NSString *)description
                           allowOverride:(BOOL)allowOverride;

@property (nonatomic, getter=isEnabled) BOOL enabled;
@property (nonatomic, readonly) NSString *keyboardShortcutsDescription;

@end
