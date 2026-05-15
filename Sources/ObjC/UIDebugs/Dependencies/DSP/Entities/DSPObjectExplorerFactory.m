#import "DSPObjectExplorerFactory.h"
#import "DSPGlobalsViewController.h"
#import "DSPClassShortcuts.h"
#import "DSPViewShortcuts.h"
#import "DSPWindowShortcuts.h"
#import "DSPViewControllerShortcuts.h"
#import "DSPUIAppShortcuts.h"
#import "DSPImageShortcuts.h"
#import "DSPLayerShortcuts.h"
#import "DSPColorPreviewSection.h"
#import "DSPDefaultsContentSection.h"
#import "DSPBundleShortcuts.h"
#import "DSPNSStringShortcuts.h"
#import "DSPNSDataShortcuts.h"
#import "DSPBlockShortcuts.h"
#import "DSPUtility.h"

@implementation DSPObjectExplorerFactory
static NSMutableDictionary<id<NSCopying>, Class> *classesToRegisteredSections = nil;

+ (void)initialize {
    if (self == [DSPObjectExplorerFactory class]) {
        // DO NOT USE STRING KEYS HERE
        // We NEED to use the class as a key, because we CANNOT
        // differentiate a class's name from the metaclass's name.
        // These mappings are per-class-object, not per-class-name.
        //
        // For example, if we used class names, this would result in
        // the object explorer trying to render a color preview for
        // the UIColor class object, which is not a color itself.
        #define ClassKey(name) (id<NSCopying>)[name class]
        #define ClassKeyByName(str) (id<NSCopying>)NSClassFromString(@ #str)
        #define MetaclassKey(meta) (id<NSCopying>)object_getClass([meta class])
        classesToRegisteredSections = [NSMutableDictionary dictionaryWithDictionary:@{
            MetaclassKey(NSObject)     : [DSPClassShortcuts class],
            ClassKey(NSArray)          : [DSPCollectionContentSection class],
            ClassKey(NSSet)            : [DSPCollectionContentSection class],
            ClassKey(NSDictionary)     : [DSPCollectionContentSection class],
            ClassKey(NSOrderedSet)     : [DSPCollectionContentSection class],
            ClassKey(NSUserDefaults)   : [DSPDefaultsContentSection class],
            ClassKey(UIViewController) : [DSPViewControllerShortcuts class],
            ClassKey(UIApplication)    : [DSPUIAppShortcuts class],
            ClassKey(UIView)           : [DSPViewShortcuts class],
            ClassKey(UIWindow)         : [DSPWindowShortcuts class],
            ClassKey(UIImage)          : [DSPImageShortcuts class],
            ClassKey(CALayer)          : [DSPLayerShortcuts class],
            ClassKey(UIColor)          : [DSPColorPreviewSection class],
            ClassKey(NSBundle)         : [DSPBundleShortcuts class],
            ClassKey(NSString)         : [DSPNSStringShortcuts class],
            ClassKey(NSData)           : [DSPNSDataShortcuts class],
            ClassKeyByName(NSBlock)    : [DSPBlockShortcuts class],
        }];
        #undef ClassKey
        #undef ClassKeyByName
        #undef MetaclassKey
    }
}

+ (DSPObjectExplorerViewController *)explorerViewControllerForObject:(id)object {
    // Can't explore nil
    if (!object) {
        return nil;
    }

    // If we're given an object, this will look up it's class hierarchy
    // until it finds a registration. This will work for KVC classes,
    // since they are children of the original class, and not siblings.
    // If we are given an object, object_getClass will return a metaclass,
    // and the same thing will happen. DSPClassShortcuts is the default
    // shortcut section for NSObject.
    //
    // TODO: rename it to DSPNSObjectShortcuts or something?
    DSPShortcutsSection *shortcutsSection = [DSPShortcutsSection forObject:object];
    NSArray *sections = @[shortcutsSection];
    
    Class customSectionClass = nil;
    Class cls = object_getClass(object);
    do {
        customSectionClass = classesToRegisteredSections[(id<NSCopying>)cls];
    } while (!customSectionClass && (cls = [cls superclass]));

    if (customSectionClass) {
        id customSection = [customSectionClass forObject:object];
        BOOL isDSPShortcutSection = [customSection respondsToSelector:@selector(isNewSection)];
        
        // If the section "replaces" the default shortcuts section,
        // only return that section. Otherwise, return both this
        // section and the default shortcuts section.
        if (isDSPShortcutSection && ![customSection isNewSection]) {
            sections = @[customSection];
        } else {
            // Custom section will go before shortcuts
            sections = @[customSection, shortcutsSection];            
        }
    }

    return [DSPObjectExplorerViewController
        exploringObject:object
        customSections:sections
    ];
}

+ (void)registerExplorerSection:(Class)explorerClass forClass:(Class)objectClass {
    classesToRegisteredSections[(id<NSCopying>)objectClass] = explorerClass;
}

#pragma mark - DSPGlobalsEntry

+ (NSString *)globalsEntryTitle:(DSPGlobalsRow)row  {
    switch (row) {
        case DSPGlobalsRowAppDelegate:
            return @"🎟  App Delegate";
        case DSPGlobalsRowKeyWindow:
            return @"🔑  Key Window";
        case DSPGlobalsRowRootViewController:
            return @"🌴  Root View Controller";
        case DSPGlobalsRowProcessInfo:
            return @"🚦  NSProcessInfo.processInfo";
        case DSPGlobalsRowUserDefaults:
            return @"💾  Preferences";
        case DSPGlobalsRowMainBundle:
            return @"📦  NSBundle.mainBundle";
        case DSPGlobalsRowApplication:
            return @"🚀  UIApplication.sharedApplication";
        case DSPGlobalsRowMainScreen:
            return @"💻  UIScreen.mainScreen";
        case DSPGlobalsRowCurrentDevice:
            return @"📱  UIDevice.currentDevice";
        case DSPGlobalsRowPasteboard:
            return @"📋  UIPasteboard.generalPasteboard";
        case DSPGlobalsRowURLSession:
            return @"📡  NSURLSession.sharedSession";
        case DSPGlobalsRowURLCache:
            return @"⏳  NSURLCache.sharedURLCache";
        case DSPGlobalsRowNotificationCenter:
            return @"🔔  NSNotificationCenter.defaultCenter";
        case DSPGlobalsRowMenuController:
            return @"📎  UIMenuController.sharedMenuController";
        case DSPGlobalsRowFileManager:
            return @"🗄  NSFileManager.defaultManager";
        case DSPGlobalsRowTimeZone:
            return @"🌎  NSTimeZone.systemTimeZone";
        case DSPGlobalsRowLocale:
            return @"🗣  NSLocale.currentLocale";
        case DSPGlobalsRowCalendar:
            return @"📅  NSCalendar.currentCalendar";
        case DSPGlobalsRowMainRunLoop:
            return @"🏃🏻‍♂️  NSRunLoop.mainRunLoop";
        case DSPGlobalsRowMainThread:
            return @"🧵  NSThread.mainThread";
        case DSPGlobalsRowOperationQueue:
            return @"📚  NSOperationQueue.mainQueue";
        default: return nil;
    }
}

+ (UIViewController *)globalsEntryViewController:(DSPGlobalsRow)row  {
    switch (row) {
        case DSPGlobalsRowAppDelegate: {
            id<UIApplicationDelegate> appDelegate = UIApplication.sharedApplication.delegate;
            return [self explorerViewControllerForObject:appDelegate];
        }
        case DSPGlobalsRowProcessInfo:
            return [self explorerViewControllerForObject:NSProcessInfo.processInfo];
        case DSPGlobalsRowUserDefaults:
            return [self explorerViewControllerForObject:NSUserDefaults.standardUserDefaults];
        case DSPGlobalsRowMainBundle:
            return [self explorerViewControllerForObject:NSBundle.mainBundle];
        case DSPGlobalsRowApplication:
            return [self explorerViewControllerForObject:UIApplication.sharedApplication];
        case DSPGlobalsRowMainScreen:
            return [self explorerViewControllerForObject:UIScreen.mainScreen];
        case DSPGlobalsRowCurrentDevice:
            return [self explorerViewControllerForObject:UIDevice.currentDevice];
        case DSPGlobalsRowPasteboard:
            return [self explorerViewControllerForObject:UIPasteboard.generalPasteboard];
        case DSPGlobalsRowURLSession:
            return [self explorerViewControllerForObject:NSURLSession.sharedSession];
        case DSPGlobalsRowURLCache:
            return [self explorerViewControllerForObject:NSURLCache.sharedURLCache];
        case DSPGlobalsRowNotificationCenter:
            return [self explorerViewControllerForObject:NSNotificationCenter.defaultCenter];
        case DSPGlobalsRowMenuController:
            return [self explorerViewControllerForObject:UIMenuController.sharedMenuController];
        case DSPGlobalsRowFileManager:
            return [self explorerViewControllerForObject:NSFileManager.defaultManager];
        case DSPGlobalsRowTimeZone:
            return [self explorerViewControllerForObject:NSTimeZone.systemTimeZone];
        case DSPGlobalsRowLocale:
            return [self explorerViewControllerForObject:NSLocale.currentLocale];
        case DSPGlobalsRowCalendar:
            return [self explorerViewControllerForObject:NSCalendar.currentCalendar];
        case DSPGlobalsRowMainRunLoop:
            return [self explorerViewControllerForObject:NSRunLoop.mainRunLoop];
        case DSPGlobalsRowMainThread:
            return [self explorerViewControllerForObject:NSThread.mainThread];
        case DSPGlobalsRowOperationQueue:
            return [self explorerViewControllerForObject:NSOperationQueue.mainQueue];

        case DSPGlobalsRowKeyWindow:
            return [DSPObjectExplorerFactory
                explorerViewControllerForObject:DSPUtility.appKeyWindow
            ];
        case DSPGlobalsRowRootViewController: {
            id<UIApplicationDelegate> delegate = UIApplication.sharedApplication.delegate;
            if ([delegate respondsToSelector:@selector(window)]) {
                return [self explorerViewControllerForObject:delegate.window.rootViewController];
            }

            return nil;
        }
        
        case DSPGlobalsRowNetworkHistory:
        case DSPGlobalsRowSystemLog:
        case DSPGlobalsRowLiveObjects:
        case DSPGlobalsRowAddressInspector:
        case DSPGlobalsRowCookies:
        case DSPGlobalsRowBrowseRuntime:
        case DSPGlobalsRowAppKeychainItems:
        case DSPGlobalsRowPushNotifications:
        case DSPGlobalsRowBrowseBundle:
        case DSPGlobalsRowBrowseContainer:
        case DSPGlobalsRowCount:
            return nil;
    }
    
    return nil;
}

+ (DSPGlobalsEntryRowAction)globalsEntryRowAction:(DSPGlobalsRow)row {
    switch (row) {
        case DSPGlobalsRowRootViewController: {
            // Check if the app delegate responds to -window. If not, present an alert
            return ^(UITableViewController *host) {
                id<UIApplicationDelegate> delegate = UIApplication.sharedApplication.delegate;
                if ([delegate respondsToSelector:@selector(window)]) {
                    UIViewController *explorer = [self explorerViewControllerForObject:
                        delegate.window.rootViewController
                    ];
                    [host.navigationController pushViewController:explorer animated:YES];
                } else {
                    NSString *msg = @"The app delegate doesn't respond to -window";
                    [DSPAlert showAlert:@":(" message:msg from:host];
                }
            };
        }
        default: return nil;
    }
}

@end
