#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString *const kDSPNetworkObserverEnabledStateChangedNotification;

/// This class swizzles NSURLConnection and NSURLSession delegate methods to observe events in the URL loading system.
/// High level network events are sent to the default DSPNetworkRecorder instance which maintains the request history and caches response bodies.
@interface DSPNetworkObserver : NSObject

/// Swizzling occurs when the observer is enabled for the first time.
/// This reduces the impact of DSP if network debugging is not desired.
/// NOTE: this setting persists between launches of the app.
@property (nonatomic, class, getter=isEnabled) BOOL enabled;

@end
