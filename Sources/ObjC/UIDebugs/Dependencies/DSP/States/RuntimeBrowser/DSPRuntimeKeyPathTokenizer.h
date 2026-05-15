#import "DSPRuntimeKeyPath.h"

@interface DSPRuntimeKeyPathTokenizer : NSObject

+ (NSUInteger)tokenCountOfString:(NSString *)userInput;
+ (DSPRuntimeKeyPath *)tokenizeString:(NSString *)userInput;

+ (BOOL)allowedInKeyPath:(NSString *)text;

@end
