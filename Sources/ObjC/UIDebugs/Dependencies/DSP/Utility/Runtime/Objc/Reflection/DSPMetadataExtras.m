#import "DSPMetadataExtras.h"

NSString * const DSPAuxiliaryInfoKeyFieldLabels = @"DSPAuxiliaryInfoKeyFieldLabels";
NSString * const DSPAuxiliarynfoKeyFieldLabels = @"DSPAuxiliarynfoKeyFieldLabels";

@implementation DSPMethodBase (Auxiliary)
- (id)auxiliaryInfoForKey:(NSString *)key { return nil; }
@end

@implementation DSPProperty (Auxiliary)
- (id)auxiliaryInfoForKey:(NSString *)key { return nil; }
@end

@implementation DSPIvar (Auxiliary)
- (id)auxiliaryInfoForKey:(NSString *)key { return nil; }
@end
