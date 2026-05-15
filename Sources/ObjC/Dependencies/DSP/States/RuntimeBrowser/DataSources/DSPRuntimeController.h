#import "DSPRuntimeKeyPath.h"

/// Wraps DSPRuntimeClient and provides extra caching mechanisms
@interface DSPRuntimeController : NSObject

/// @return An array of strings if the key path only evaluates
///         to a class or bundle; otherwise, a list of lists of DSPMethods.
+ (NSArray *)dataForKeyPath:(DSPRuntimeKeyPath *)keyPath;

/// Useful when you need to specify which classes to search in.
/// \c dataForKeyPath: will only search classes matching the class key.
/// We use this elsewhere when we need to search a class hierarchy.
+ (NSArray<NSArray<DSPMethod *> *> *)methodsForToken:(DSPSearchToken *)token
                                             instance:(NSNumber *)onlyInstanceMethods
                                            inClasses:(NSArray<NSString*> *)classes;

/// Useful when you need the classes that are associated with the
/// double list of methods returned from \c dataForKeyPath
+ (NSMutableArray<NSString *> *)classesForKeyPath:(DSPRuntimeKeyPath *)keyPath;

+ (NSString *)shortBundleNameForClass:(NSString *)name;

+ (NSString *)imagePathWithShortName:(NSString *)suffix;

/// Gives back short names. For example, "Foundation.framework"
+ (NSArray<NSString*> *)allBundleNames;

@end
