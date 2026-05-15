#import "DSPShortcutsFactory+Defaults.h"
#import "DSPShortcut.h"
#import "DSPMacros.h"
#import "DSPRuntimeUtility.h"
#import "NSArray+DSP.h"
#import "NSObject+DSP_Reflection.h"
#import "DSPObjcInternal.h"
#import "Cocoa+DSPShortcuts.h"

#pragma mark - UIApplication

@implementation DSPShortcutsFactory (UIApplication)

+ (void)load { DSP_EXIT_IF_NO_CTORS()
    // sharedApplication class property possibly not added
    // as a literal class property until iOS 10
    DSPRuntimeUtilityTryAddObjectProperty(
        2, sharedApplication, UIApplication.dsp_metaclass, UIApplication, PropertyKey(ReadOnly)
    );
    
    self.append.classProperties(@[@"sharedApplication"]).forClass(UIApplication.dsp_metaclass);
    self.append.properties(@[
        @"delegate", @"keyWindow", @"windows"
    ]).forClass(UIApplication.class);

    if (@available(iOS 13, *)) {
        self.append.properties(@[
            @"connectedScenes", @"openSessions", @"supportsMultipleScenes"
        ]).forClass(UIApplication.class);
    }
}

@end

#pragma mark - Views

@implementation DSPShortcutsFactory (Views)

+ (void)load { DSP_EXIT_IF_NO_CTORS()
    // A quirk of UIView and some other classes: a lot of the `@property`s are
    // not actually properties from the perspective of the runtime.
    //
    // We add these properties to the class at runtime if they haven't been added yet.
    // This way, we can use our property editor to access and change them.
    // The property attributes match the declared attributes in their headers.

    // UIView, public
    Class UIView_ = UIView.class;
    DSPRuntimeUtilityTryAddNonatomicProperty(2, frame, UIView_, CGRect);
    DSPRuntimeUtilityTryAddNonatomicProperty(2, alpha, UIView_, CGFloat);
    DSPRuntimeUtilityTryAddNonatomicProperty(2, clipsToBounds, UIView_, BOOL);
    DSPRuntimeUtilityTryAddNonatomicProperty(2, opaque, UIView_, BOOL, PropertyKeyGetter(isOpaque));
    DSPRuntimeUtilityTryAddNonatomicProperty(2, hidden, UIView_, BOOL, PropertyKeyGetter(isHidden));
    DSPRuntimeUtilityTryAddObjectProperty(2, backgroundColor, UIView_, UIColor, PropertyKey(Copy));
    DSPRuntimeUtilityTryAddObjectProperty(6, constraints, UIView_, NSArray, PropertyKey(ReadOnly));
    DSPRuntimeUtilityTryAddObjectProperty(2, subviews, UIView_, NSArray, PropertyKey(ReadOnly));
    DSPRuntimeUtilityTryAddObjectProperty(2, superview, UIView_, UIView, PropertyKey(ReadOnly));
    DSPRuntimeUtilityTryAddObjectProperty(7, tintColor, UIView_, UIView);

    // UIButton, private
    DSPRuntimeUtilityTryAddObjectProperty(2, font, UIButton.class, UIFont, PropertyKey(ReadOnly));
    
    // Only available since iOS 3.2, but we never supported iOS 3, so who cares
    NSArray *ivars = @[@"_gestureRecognizers"];
    NSArray *methods = @[@"sizeToFit", @"setNeedsLayout", @"removeFromSuperview"];

    // UIView
    self.append.ivars(ivars).methods(methods).properties(@[
        @"frame", @"bounds", @"center", @"transform",
        @"backgroundColor", @"alpha", @"opaque", @"hidden",
        @"clipsToBounds", @"userInteractionEnabled", @"layer",
        @"superview", @"subviews",
        @"accessibilityIdentifier", @"accessibilityLabel"
    ]).forClass(UIView.class);

    // UILabel
    self.append.ivars(ivars).methods(methods).properties(@[
        @"text", @"attributedText", @"font", @"frame",
        @"textColor", @"textAlignment", @"numberOfLines",
        @"lineBreakMode", @"enabled", @"backgroundColor",
        @"alpha", @"hidden", @"preferredMaxLayoutWidth",
        @"superview", @"subviews",
        @"accessibilityIdentifier", @"accessibilityLabel"
    ]).forClass(UILabel.class);

    // UIWindow
    self.append.ivars(ivars).properties(@[
        @"rootViewController", @"windowLevel", @"keyWindow",
        @"frame", @"bounds", @"center", @"transform",
        @"backgroundColor", @"alpha", @"opaque", @"hidden",
        @"clipsToBounds", @"userInteractionEnabled", @"layer",
        @"subviews"
    ]).forClass(UIWindow.class);

    if (@available(iOS 13, *)) {
        self.append.properties(@[@"windowScene"]).forClass(UIWindow.class);
    }

    ivars = @[@"_targetActions", @"_gestureRecognizers"];
    
    // Property was added in iOS 10 but we want it on iOS 9 too
    DSPRuntimeUtilityTryAddObjectProperty(9, allTargets, UIControl.class, NSArray, PropertyKey(ReadOnly));

    // UIControl
    self.append.ivars(ivars).methods(methods).properties(@[
        @"enabled", @"allTargets", @"frame",
        @"backgroundColor", @"hidden", @"clipsToBounds",
        @"userInteractionEnabled", @"superview", @"subviews",
        @"accessibilityIdentifier", @"accessibilityLabel"
    ]).forClass(UIControl.class);

    // UIButton
    self.append.ivars(ivars).properties(@[
        @"titleLabel", @"font", @"imageView", @"tintColor",
        @"currentTitle", @"currentImage", @"enabled", @"frame",
        @"superview", @"subviews",
        @"accessibilityIdentifier", @"accessibilityLabel"
    ]).forClass(UIButton.class);
    
    // UIImageView
    self.append.properties(@[
        @"image", @"animationImages", @"frame", @"bounds", @"center",
        @"transform", @"alpha", @"hidden", @"clipsToBounds",
        @"userInteractionEnabled", @"layer", @"superview", @"subviews",
        @"accessibilityIdentifier", @"accessibilityLabel"
    ]).forClass(UIImageView.class);
}

@end


#pragma mark - View Controllers

@implementation DSPShortcutsFactory (ViewControllers)

+ (void)load { DSP_EXIT_IF_NO_CTORS()
    // toolbarItems is not really a property, make it one 
    DSPRuntimeUtilityTryAddObjectProperty(3, toolbarItems, UIViewController.class, NSArray);
    
    // UIViewController
    self.append
        .properties(@[
            @"viewIfLoaded", @"title", @"navigationItem", @"toolbarItems", @"tabBarItem",
            @"childViewControllers", @"navigationController", @"tabBarController", @"splitViewController",
            @"parentViewController", @"presentedViewController", @"presentingViewController",
        ])
        .methods(@[@"view"])
        .forClass(UIViewController.class);
    
    // UIAlertController
    NSMutableArray *alertControllerProps = @[
        @"title", @"message", @"actions", @"textFields",
        @"preferredAction", @"presentingViewController", @"viewIfLoaded",
    ].mutableCopy;
    if (@available(iOS 14.0, *)) {
        [alertControllerProps insertObject:@"image" atIndex:4];
    }
    self.append
        .properties(alertControllerProps)
        .methods(@[@"addAction:"])
        .forClass(UIAlertController.class);
    self.append.properties(@[
        @"title", @"style", @"enabled", @"dsp_styleName",
        @"image", @"keyCommandInput", @"_isPreferred", @"_alertController",
    ]).forClass(UIAlertAction.class);
}

@end


#pragma mark - UIImage

@implementation DSPShortcutsFactory (UIImage)

+ (void)load { DSP_EXIT_IF_NO_CTORS()
    self.append.methods(@[
        @"CGImage", @"CIImage"
    ]).properties(@[
        @"scale", @"size", @"capInsets",
        @"alignmentRectInsets", @"duration", @"images"
    ]).forClass(UIImage.class);

    if (@available(iOS 13, *)) {
        self.append.properties(@[@"symbolImage"]).forClass(UIImage.class);
    }
}

@end


#pragma mark - NSBundle

@implementation DSPShortcutsFactory (NSBundle)

+ (void)load { DSP_EXIT_IF_NO_CTORS()
    self.append.properties(@[
        @"bundleIdentifier", @"principalClass",
        @"infoDictionary", @"bundlePath",
        @"executablePath", @"loaded"
    ]).forClass(NSBundle.class);
}

@end


#pragma mark - Classes

@implementation DSPShortcutsFactory (Classes)

+ (void)load { DSP_EXIT_IF_NO_CTORS()
    self.append.classMethods(@[@"new", @"alloc"]).forClass(NSObject.dsp_metaclass);
}

@end


#pragma mark - Activities

@implementation DSPShortcutsFactory (Activities)

+ (void)load { DSP_EXIT_IF_NO_CTORS()
    // Property was added in iOS 10 but we want it on iOS 9 too
    DSPRuntimeUtilityTryAddNonatomicProperty(9, item, UIActivityItemProvider.class, id, PropertyKey(ReadOnly));
    
    self.append.properties(@[
        @"item", @"placeholderItem", @"activityType"
    ]).forClass(UIActivityItemProvider.class);

    self.append.properties(@[
        @"activityItems", @"applicationActivities", @"excludedActivityTypes", @"completionHandler"
    ]).forClass(UIActivityViewController.class);
}

@end


#pragma mark - Blocks

@implementation DSPShortcutsFactory (Blocks)

+ (void)load { DSP_EXIT_IF_NO_CTORS()
    self.append.methods(@[@"invoke"]).forClass(NSClassFromString(@"NSBlock"));
}

@end

#pragma mark - Foundation

@implementation DSPShortcutsFactory (Foundation)

+ (void)load { DSP_EXIT_IF_NO_CTORS()
    self.append.properties(@[
        @"configuration", @"delegate", @"delegateQueue", @"sessionDescription",
    ]).methods(@[
        @"dataTaskWithURL:", @"finishTasksAndInvalidate", @"invalidateAndCancel",
    ]).forClass(NSURLSession.class);
    
    self.append.methods(@[
        @"cachedResponseForRequest:", @"storeCachedResponse:forRequest:",
        @"storeCachedResponse:forDataTask:", @"removeCachedResponseForRequest:",
        @"removeCachedResponseForDataTask:", @"removeCachedResponsesSinceDate:",
        @"removeAllCachedResponses",
    ]).forClass(NSURLCache.class);
    
    
    self.append.methods(@[
        @"postNotification:", @"postNotificationName:object:userInfo:",
        @"addObserver:selector:name:object:", @"removeObserver:",
        @"removeObserver:name:object:",
    ]).forClass(NSNotificationCenter.class);
    
    // NSTimeZone class properties aren't real properties
    DSPRuntimeUtilityTryAddObjectProperty(2, localTimeZone, NSTimeZone.dsp_metaclass, NSTimeZone);
    DSPRuntimeUtilityTryAddObjectProperty(2, systemTimeZone, NSTimeZone.dsp_metaclass, NSTimeZone);
    DSPRuntimeUtilityTryAddObjectProperty(2, defaultTimeZone, NSTimeZone.dsp_metaclass, NSTimeZone);
    DSPRuntimeUtilityTryAddObjectProperty(2, knownTimeZoneNames, NSTimeZone.dsp_metaclass, NSArray);
    DSPRuntimeUtilityTryAddObjectProperty(2, abbreviationDictionary, NSTimeZone.dsp_metaclass, NSDictionary);
    
    self.append.classMethods(@[
        @"timeZoneWithName:", @"timeZoneWithAbbreviation:", @"timeZoneForSecondsFromGMT:",
    ]).forClass(NSTimeZone.dsp_metaclass);
    
    self.append.classProperties(@[
        @"defaultTimeZone", @"systemTimeZone", @"localTimeZone",
    ]).forClass(NSTimeZone.class);
    
    // UTF8String is not a real property under the hood
    DSPRuntimeUtilityTryAddNonatomicProperty(2, UTF8String, NSString.class, const char *, PropertyKey(ReadOnly));
    
    self.append.properties(@[@"length"]).methods(@[@"characterAtIndex:"]).forClass(NSString.class);
    self.append.methods(@[
        @"writeToFile:atomically:", @"subdataWithRange:", @"isEqualToData:",
    ]).properties(@[
        @"length", @"bytes",
    ]).forClass(NSData.class);
    
    self.append.classMethods(@[
        @"dataWithJSONObject:options:error:",
        @"JSONObjectWithData:options:error:",
        @"isValidJSONObject:",
    ]).forClass(NSJSONSerialization.class);
    
    // NSArray
    self.append.classMethods(@[
        @"arrayWithObject:", @"arrayWithContentsOfFile:"
    ]).forClass(NSArray.dsp_metaclass);
    self.append.methods(@[
        @"valueForKeyPath:", @"subarrayWithRange:",
        @"arrayByAddingObject:", @"arrayByAddingObjectsFromArray:",
        @"filteredArrayUsingPredicate:", @"subarrayWithRange:",
        @"containsObject:", @"objectAtIndex:", @"indexOfObject:",
        @"makeObjectsPerformSelector:", @"makeObjectsPerformSelector:withObject:",
        @"sortedArrayUsingSelector:", @"reverseObjectEnumerator",
        @"isEqualToArray:", @"mutableCopy",
    ]).forClass(NSArray.class);
    // NSDictionary
    self.append.methods(@[
        @"objectForKey:", @"valueForKeyPath:",
        @"isEqualToDictionary:", @"mutableCopy",
    ]).forClass(NSDictionary.class);
    // NSSet
    self.append.classMethods(@[
        @"setWithObject:", @"setWithArray:"
    ]).forClass(NSSet.dsp_metaclass);
    self.append.methods(@[
        @"allObjects", @"valueForKeyPath:", @"containsObject:",
        @"setByAddingObject:", @"setByAddingObjectsFromArray:",
        @"filteredSetUsingPredicate:", @"isSubsetOfSet:",
        @"makeObjectsPerformSelector:", @"makeObjectsPerformSelector:withObject:",
        @"reverseObjectEnumerator", @"isEqualToSet:", @"mutableCopy",
    ]).forClass(NSSet.class);
    
    // NSMutableArray
    self.prepend.methods(@[
        @"addObject:", @"insertObject:atIndex:", @"addObjectsFromArray:", 
        @"removeObject:", @"removeObjectAtIndex:",
        @"removeObjectsInArray:", @"removeAllObjects", 
        @"removeLastObject", @"filterUsingPredicate:",
        @"sortUsingSelector:", @"copy",
    ]).forClass(NSMutableArray.class);
    // NSMutableDictionary
    self.prepend.methods(@[
        @"setObject:forKey:", @"removeObjectForKey:",
        @"removeAllObjects", @"removeObjectsForKeys:", @"copy",
    ]).forClass(NSMutableDictionary.class);
    // NSMutableSet
    self.prepend.methods(@[
        @"addObject:", @"removeObject:", @"filterUsingPredicate:",
        @"removeAllObjects", @"addObjectsFromArray:",
        @"unionSet:", @"minusSet:", @"intersectSet:", @"copy"
    ]).forClass(NSMutableSet.class);
    
    self.append.methods(@[@"nextObject", @"allObjects"]).forClass(NSEnumerator.class);
    
    self.append.properties(@[@"dsp_observers"]).forClass(NSNotificationCenter.class);
}

@end

#pragma mark - WebKit / Safari

@implementation DSPShortcutsFactory (WebKit_Safari)

+ (void)load { DSP_EXIT_IF_NO_CTORS()
    Class WKWebView = NSClassFromString(@"WKWebView");
    Class SafariVC = NSClassFromString(@"SFSafariViewController");
    
    if (WKWebView) {
        self.append.properties(@[
            @"configuration", @"scrollView", @"title", @"URL",
            @"customUserAgent", @"navigationDelegate"
        ]).methods(@[@"reload", @"stopLoading"]).forClass(WKWebView);
    }
    
    if (SafariVC) {
        self.append.properties(@[
            @"delegate"
        ]).forClass(SafariVC);
        if (@available(iOS 10.0, *)) {
            self.append.properties(@[
                @"preferredBarTintColor", @"preferredControlTintColor"
            ]).forClass(SafariVC);
        }
        if (@available(iOS 11.0, *)) {
            self.append.properties(@[
                @"configuration", @"dismissButtonStyle"
            ]).forClass(SafariVC);
        }
    }
}

@end

#pragma mark - Pasteboard

@implementation DSPShortcutsFactory (Pasteboard)

+ (void)load { DSP_EXIT_IF_NO_CTORS()
    self.append.properties(@[
        @"name", @"numberOfItems", @"items",
        @"string", @"image", @"color", @"URL",
    ]).forClass(UIPasteboard.class);
}

@end

@interface NSNotificationCenter (Observers)
@property (readonly) NSArray<NSString *> *dsp_observers;
@end

@implementation NSNotificationCenter (Observers)
- (id)dsp_observers {
    NSString *debug = self.debugDescription;
    NSArray<NSString *> *observers = [debug componentsSeparatedByString:@"\n"];
    NSArray<NSArray<NSString *> *> *splitObservers = [observers dsp_mapped:^id(NSString *entry, NSUInteger idx) {
        return [entry componentsSeparatedByString:@","];
    }];
    
    NSArray *names = [splitObservers dsp_mapped:^id(NSArray<NSString *> *entry, NSUInteger idx) {
        return entry[0];
    }];
    NSArray *objects = [splitObservers dsp_mapped:^id(NSArray<NSString *> *entry, NSUInteger idx) {
        if (entry.count < 2) return NSNull.null;
        NSScanner *scanner = [NSScanner scannerWithString:entry[1]];

        unsigned long long objectPointerValue;
        if ([scanner scanHexLongLong:&objectPointerValue]) {
            void *objectPointer = (void *)objectPointerValue;
            if (DSPPointerIsValidObjcObject(objectPointer))
                return (__bridge id)(void *)objectPointer;
        }
        
        return NSNull.null;
    }];
    
    return [NSArray dsp_forEachUpTo:names.count map:^id(NSUInteger i) {
        return @[names[i], objects[i]];
    }];
}
@end

#pragma mark - Firebase Firestore

@implementation DSPShortcutsFactory (FirebaseFirestore)

+ (void)load { DSP_EXIT_IF_NO_CTORS()
    Class FIRDocumentSnap = NSClassFromString(@"FIRDocumentSnapshot");
    if (FIRDocumentSnap) {
        DSPRuntimeUtilityTryAddObjectProperty(2, data, FIRDocumentSnap, NSDictionary, PropertyKey(ReadOnly));        
    }
}

@end
