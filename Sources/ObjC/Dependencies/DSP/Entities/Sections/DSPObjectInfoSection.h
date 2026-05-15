#import <Foundation/Foundation.h>

/// \c DSPTableViewSection itself doesn't know about the object being explored.
/// Subclasses might need this info to provide useful information about the object. Instead
/// of adding an abstract class to the class hierarchy, subclasses can conform to this protocol
/// to indicate that the only info they need to be initialized is the object being explored.
@protocol DSPObjectInfoSection <NSObject>

+ (instancetype)forObject:(id)object;

@end
