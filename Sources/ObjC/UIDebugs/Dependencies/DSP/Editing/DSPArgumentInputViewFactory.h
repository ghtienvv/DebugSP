#import <Foundation/Foundation.h>
#import "DSPArgumentInputSwitchView.h"

@interface DSPArgumentInputViewFactory : NSObject

/// Forwards to argumentInputViewForTypeEncoding:currentValue: with a nil currentValue.
+ (DSPArgumentInputView *)argumentInputViewForTypeEncoding:(const char *)typeEncoding;

/// The main factory method for making argument input view subclasses that are the best fit for the type.
+ (DSPArgumentInputView *)argumentInputViewForTypeEncoding:(const char *)typeEncoding currentValue:(id)currentValue;

/// A way to check if we should try editing a filed given its type encoding and value.
/// Useful when deciding whether to edit or explore a property, ivar, or NSUserDefaults value.
+ (BOOL)canEditFieldWithTypeEncoding:(const char *)typeEncoding currentValue:(id)currentValue;

/// Enable displaying ivar names for custom struct types
+ (void)registerFieldNames:(NSArray<NSString *> *)names forTypeEncoding:(NSString *)typeEncoding;

@end
