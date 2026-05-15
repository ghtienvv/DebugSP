#import "DSPTableViewSection.h"
#import "States/Globals/DSPGlobalsEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface DSPGlobalsSection : DSPTableViewSection

+ (instancetype)title:(NSString *)title rows:(NSArray<DSPGlobalsEntry *> *)rows;

@end

NS_ASSUME_NONNULL_END
