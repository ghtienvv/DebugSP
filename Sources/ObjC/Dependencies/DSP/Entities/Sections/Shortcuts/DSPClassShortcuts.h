#import "DSPShortcutsSection.h"

/// Provides handy shortcuts for class objects.
/// This is the default section used for all class objects.
@interface DSPClassShortcuts : DSPShortcutsSection

+ (instancetype)forObject:(Class)cls;

@end
