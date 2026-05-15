#import <Foundation/Foundation.h>

// Only use these if the getters and setters aren't good enough for whatever reason
extern NSString * const kDSPDefaultsToolbarTopMarginKey;
extern NSString * const kDSPDefaultsPersistentOSLogKey;
// Compatibility alias for older source references.
extern NSString * const kDSPDefaultsiOSPersistentOSLogKey;
extern NSString * const kDSPDefaultsHidePropertyIvarsKey;
extern NSString * const kDSPDefaultsHidePropertyMethodsKey;
extern NSString * const kDSPDefaultsHidePrivateMethodsKey;
extern NSString * const kDSPDefaultsShowMethodOverridesKey;
extern NSString * const kDSPDefaultsHideVariablePreviewsKey;
extern NSString * const kDSPDefaultsNetworkObserverEnabledKey;
extern NSString * const kDSPDefaultsNetworkHostDenylistKey;
extern NSString * const kDSPDefaultsDisableOSLogForceASLKey;
extern NSString * const kDSPDefaultsAPNSCaptureEnabledKey;
extern NSString * const kDSPDefaultsRegisterJSONExplorerKey;

/// All BOOL preferences are NO by default
@interface NSUserDefaults (DSP)

- (void)dsp_toggleBoolForKey:(NSString *)key;

@property (nonatomic) double dsp_toolbarTopMargin;

@property (nonatomic) BOOL dsp_networkObserverEnabled;
// Not actually stored in defaults, but written to a file
@property (nonatomic) NSArray<NSString *> *dsp_networkHostDenylist;

/// Whether or not to register the object explorer as a JSON viewer on launch
@property (nonatomic) BOOL dsp_registerDictionaryJSONViewerOnLaunch;

/// The last selected screen in the network observer
@property (nonatomic) NSInteger dsp_lastNetworkObserverMode;

/// Disable os_log and re-enable ASL. May break Console.app output.
@property (nonatomic) BOOL dsp_disableOSLog;
@property (nonatomic) BOOL dsp_cacheOSLogMessages;

@property (nonatomic) BOOL dsp_enableAPNSCapture;

@property (nonatomic) BOOL dsp_explorerHidesPropertyIvars;
@property (nonatomic) BOOL dsp_explorerHidesPropertyMethods;
@property (nonatomic) BOOL dsp_explorerHidesPrivateMethods;
@property (nonatomic) BOOL dsp_explorerShowsMethodOverrides;
@property (nonatomic) BOOL dsp_explorerHidesVariablePreviews;

@end
