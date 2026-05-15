#import <Foundation/Foundation.h>
#import "DSPProperty.h"
#import "DSPIvar.h"
#import "DSPMethodBase.h"
#import "DSPProtocol.h"

@interface DSPProperty (Compare)
- (NSComparisonResult)compare:(DSPProperty *)other;
@end

@interface DSPIvar (Compare)
- (NSComparisonResult)compare:(DSPIvar *)other;
@end

@interface DSPMethodBase (Compare)
- (NSComparisonResult)compare:(DSPMethodBase *)other;
@end

@interface DSPProtocol (Compare)
- (NSComparisonResult)compare:(DSPProtocol *)other;
@end
