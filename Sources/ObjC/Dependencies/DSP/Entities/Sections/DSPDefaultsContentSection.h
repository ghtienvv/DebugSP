#import "DSPCollectionContentSection.h"
#import "DSPObjectInfoSection.h"

@interface DSPDefaultsContentSection : DSPCollectionContentSection <DSPObjectInfoSection>

/// Uses \c NSUserDefaults.standardUserDefaults
+ (instancetype)standard;
+ (instancetype)forDefaults:(NSUserDefaults *)userDefaults;

/// Whether or not to filter out keys not present in the app's user defaults file.
///
/// This is useful for filtering out some useless keys that seem to appear
/// in every app's defaults but are never actually used or touched by the app.
/// Only applies to instances using \c NSUserDefaults.standardUserDefaults.
/// This is the default for any instance using \c standardUserDefaults, so
/// you must opt-out in those instances if you don't want this behavior.
@property (nonatomic) BOOL onlyShowKeysForAppPrefs;

@end
