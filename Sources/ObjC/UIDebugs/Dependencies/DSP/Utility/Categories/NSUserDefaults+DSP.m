#import "NSUserDefaults+DSP.h"

NSString * const kDSPDefaultsToolbarTopMarginKey = @"com.dsp.DSPToolbar.topMargin";
NSString * const kDSPDefaultsPersistentOSLogKey = @"com.flipboard.dsp.enable_persistent_os_log";
NSString * const kDSPDefaultsiOSPersistentOSLogKey = @"com.flipboard.dsp.enable_persistent_os_log";
NSString * const kDSPDefaultsHidePropertyIvarsKey = @"com.flipboard.DSP.hide_property_ivars";
NSString * const kDSPDefaultsHidePropertyMethodsKey = @"com.flipboard.DSP.hide_property_methods";
NSString * const kDSPDefaultsHidePrivateMethodsKey = @"com.flipboard.DSP.hide_private_or_namespaced_methods";
NSString * const kDSPDefaultsShowMethodOverridesKey = @"com.flipboard.DSP.show_method_overrides";
NSString * const kDSPDefaultsHideVariablePreviewsKey = @"com.flipboard.DSP.hide_variable_previews";
NSString * const kDSPDefaultsNetworkObserverEnabledKey = @"com.dsp.DSPNetworkObserver.enableOnLaunch";
NSString * const kDSPDefaultsNetworkObserverLastModeKey = @"com.dsp.DSPNetworkObserver.lastMode";
NSString * const kDSPDefaultsNetworkHostDenylistKey = @"com.flipboard.DSP.network_host_denylist";
NSString * const kDSPDefaultsDisableOSLogForceASLKey = @"com.flipboard.DSP.try_disable_os_log";
NSString * const kDSPDefaultsAPNSCaptureEnabledKey = @"com.flipboard.DSP.capture_apns";
NSString * const kDSPDefaultsRegisterJSONExplorerKey = @"com.flipboard.DSP.view_json_as_object";

static NSString * const kDSPDefaultsLegacyToolbarTopMarginKey = @"com.dsp.DSPoolbar.topMargin";
static NSString * const kDSPDefaultsLegacyiOSPersistentOSLogKey = @"com.flipborad.dsp.enable_persistent_os_log";

#define DSPDefaultsPathForFile(name) ({ \
    NSArray *paths = NSSearchPathForDirectoriesInDomains( \
        NSLibraryDirectory, NSUserDomainMask, YES \
    ); \
    [paths[0] stringByAppendingPathComponent:@"Preferences"]; \
})

@implementation NSUserDefaults (DSP)

#pragma mark Internal

/// @param filename the name of a plist file without any extension
- (NSString *)dsp_defaultsPathForFile:(NSString *)filename {
    filename = [filename stringByAppendingPathExtension:@"plist"];
    
    NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(
        NSLibraryDirectory, NSUserDomainMask, YES
    );
    NSString *preferences = [paths[0] stringByAppendingPathComponent:@"Preferences"];
    return [preferences stringByAppendingPathComponent:filename];
}

#pragma mark Helper

- (id)dsp_objectForKey:(NSString *)key migratingLegacyKey:(NSString *)legacyKey {
    id value = [self objectForKey:key];
    if (!value && legacyKey.length > 0) {
        value = [self objectForKey:legacyKey];
        if (value) {
            [self setObject:value forKey:key];
            [self removeObjectForKey:legacyKey];
        }
    }

    return value;
}

- (void)dsp_toggleBoolForKey:(NSString *)key {
    [self setBool:![self boolForKey:key] forKey:key];
    [NSNotificationCenter.defaultCenter postNotificationName:key object:nil];
}

#pragma mark Misc

- (double)dsp_toolbarTopMargin {
    NSNumber *margin = [self dsp_objectForKey:kDSPDefaultsToolbarTopMarginKey
                            migratingLegacyKey:kDSPDefaultsLegacyToolbarTopMarginKey];
    if (margin) {
        return margin.doubleValue;
    }
    
    return 100;
}

- (void)setDsp_toolbarTopMargin:(double)margin {
    [self setObject:@(margin) forKey:kDSPDefaultsToolbarTopMarginKey];
    [self removeObjectForKey:kDSPDefaultsLegacyToolbarTopMarginKey];
}

- (BOOL)dsp_networkObserverEnabled {
    return [self boolForKey:kDSPDefaultsNetworkObserverEnabledKey];
}

- (void)setDsp_networkObserverEnabled:(BOOL)enabled {
    [self setBool:enabled forKey:kDSPDefaultsNetworkObserverEnabledKey];
}

- (NSArray<NSString *> *)dsp_networkHostDenylist {
    return [NSArray arrayWithContentsOfFile:[
        self dsp_defaultsPathForFile:kDSPDefaultsNetworkHostDenylistKey
    ]] ?: @[];
}

- (void)setDsp_networkHostDenylist:(NSArray<NSString *> *)denylist {
    NSParameterAssert(denylist);
    [denylist writeToFile:[
        self dsp_defaultsPathForFile:kDSPDefaultsNetworkHostDenylistKey
    ] atomically:YES];
}

- (BOOL)dsp_registerDictionaryJSONViewerOnLaunch {
    return [self boolForKey:kDSPDefaultsRegisterJSONExplorerKey];
}

- (void)setDsp_registerDictionaryJSONViewerOnLaunch:(BOOL)enable {
    [self setBool:enable forKey:kDSPDefaultsRegisterJSONExplorerKey];
}

- (NSInteger)dsp_lastNetworkObserverMode {
    return [self integerForKey:kDSPDefaultsNetworkObserverLastModeKey];
}

- (void)setDsp_lastNetworkObserverMode:(NSInteger)mode {
    [self setInteger:mode forKey:kDSPDefaultsNetworkObserverLastModeKey];
}

#pragma mark System Log

- (BOOL)dsp_disableOSLog {
    return [self boolForKey:kDSPDefaultsDisableOSLogForceASLKey];
}

- (void)setDsp_disableOSLog:(BOOL)disable {
    [self setBool:disable forKey:kDSPDefaultsDisableOSLogForceASLKey];
}

- (BOOL)dsp_cacheOSLogMessages {
    NSNumber *cache = [self dsp_objectForKey:kDSPDefaultsPersistentOSLogKey
                           migratingLegacyKey:kDSPDefaultsLegacyiOSPersistentOSLogKey];
    return cache.boolValue;
}

- (void)setDsp_cacheOSLogMessages:(BOOL)cache {
    [self setBool:cache forKey:kDSPDefaultsPersistentOSLogKey];
    [self removeObjectForKey:kDSPDefaultsLegacyiOSPersistentOSLogKey];
    [NSNotificationCenter.defaultCenter
        postNotificationName:kDSPDefaultsPersistentOSLogKey
        object:nil
    ];
}

#pragma mark Push Notifications

- (BOOL)dsp_enableAPNSCapture {
    return [self boolForKey:kDSPDefaultsAPNSCaptureEnabledKey];
}

- (void)setDsp_enableAPNSCapture:(BOOL)enable {
    [self setBool:enable forKey:kDSPDefaultsAPNSCaptureEnabledKey];
}

#pragma mark Object Explorer

- (BOOL)dsp_explorerHidesPropertyIvars {
    return [self boolForKey:kDSPDefaultsHidePropertyIvarsKey];
}

- (void)setDsp_explorerHidesPropertyIvars:(BOOL)hide {
    [self setBool:hide forKey:kDSPDefaultsHidePropertyIvarsKey];
    [NSNotificationCenter.defaultCenter
        postNotificationName:kDSPDefaultsHidePropertyIvarsKey
        object:nil
    ];
}

- (BOOL)dsp_explorerHidesPropertyMethods {
    return [self boolForKey:kDSPDefaultsHidePropertyMethodsKey];
}

- (void)setDsp_explorerHidesPropertyMethods:(BOOL)hide {
    [self setBool:hide forKey:kDSPDefaultsHidePropertyMethodsKey];
    [NSNotificationCenter.defaultCenter
        postNotificationName:kDSPDefaultsHidePropertyMethodsKey
        object:nil
    ];
}

- (BOOL)dsp_explorerHidesPrivateMethods {
    return [self boolForKey:kDSPDefaultsHidePrivateMethodsKey];
}

- (void)setDsp_explorerHidesPrivateMethods:(BOOL)show {
    [self setBool:show forKey:kDSPDefaultsHidePrivateMethodsKey];
    [NSNotificationCenter.defaultCenter
     postNotificationName:kDSPDefaultsHidePrivateMethodsKey
        object:nil
    ];
}

- (BOOL)dsp_explorerShowsMethodOverrides {
    return [self boolForKey:kDSPDefaultsShowMethodOverridesKey];
}

- (void)setDsp_explorerShowsMethodOverrides:(BOOL)show {
    [self setBool:show forKey:kDSPDefaultsShowMethodOverridesKey];
    [NSNotificationCenter.defaultCenter
     postNotificationName:kDSPDefaultsShowMethodOverridesKey
        object:nil
    ];
}

- (BOOL)dsp_explorerHidesVariablePreviews {
    return [self boolForKey:kDSPDefaultsHideVariablePreviewsKey];
}

- (void)setDsp_explorerHidesVariablePreviews:(BOOL)hide {
    [self setBool:hide forKey:kDSPDefaultsHideVariablePreviewsKey];
    [NSNotificationCenter.defaultCenter
        postNotificationName:kDSPDefaultsHideVariablePreviewsKey
        object:nil
    ];
}

@end
