#import "DSPRuntime+Compare.h"

@implementation DSPProperty (Compare)

- (NSComparisonResult)compare:(DSPProperty *)other {
    NSComparisonResult r = [self.name caseInsensitiveCompare:other.name];
    if (r == NSOrderedSame) {
        // TODO make sure empty image name sorts above an image name
        return [self.imageName ?: @"" compare:other.imageName];
    }

    return r;
}

@end

@implementation DSPIvar (Compare)

- (NSComparisonResult)compare:(DSPIvar *)other {
    return [self.name caseInsensitiveCompare:other.name];
}

@end

@implementation DSPMethodBase (Compare)

- (NSComparisonResult)compare:(DSPMethodBase *)other {
    return [self.name caseInsensitiveCompare:other.name];
}

@end

@implementation DSPProtocol (Compare)

- (NSComparisonResult)compare:(DSPProtocol *)other {
    return [self.name caseInsensitiveCompare:other.name];
}

@end
