#import <Foundation/Foundation.h>
#import "DSPMethodBase.h"
#import "DSPProperty.h"
#import "DSPIvar.h"

NS_ASSUME_NONNULL_BEGIN

/// A dictionary mapping type encoding strings to an array of field titles
extern NSString * const DSPAuxiliaryInfoKeyFieldLabels;
// Compatibility alias for older source references.
extern NSString * const DSPAuxiliarynfoKeyFieldLabels;

@protocol DSPMetadataAuxiliaryInfo <NSObject>

/// Used to supply arbitrary additional data that need not be exposed by their own properties
- (nullable id)auxiliaryInfoForKey:(NSString *)key;

@end

@interface DSPMethodBase (Auxiliary) <DSPMetadataAuxiliaryInfo> @end
@interface DSPProperty (Auxiliary) <DSPMetadataAuxiliaryInfo> @end
@interface DSPIvar (Auxiliary) <DSPMetadataAuxiliaryInfo> @end


NS_ASSUME_NONNULL_END
