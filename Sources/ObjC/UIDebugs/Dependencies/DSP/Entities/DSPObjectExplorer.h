#import "DSPRuntime+UIKitHelpers.h"

/// Carries state about the current user defaults settings
@interface DSPObjectExplorerDefaults : NSObject
+ (instancetype)canEdit:(BOOL)editable wantsPreviews:(BOOL)showPreviews;

/// Only \c YES for properties and ivars
@property (nonatomic, readonly) BOOL isEditable;
/// Only affects properties and ivars
@property (nonatomic, readonly) BOOL wantsDynamicPreviews;
@end

@interface DSPObjectExplorer : NSObject

+ (instancetype)forObject:(id)objectOrClass;

+ (void)configureDefaultsForItems:(NSArray<id<DSPObjectExplorerItem>> *)items;

@property (nonatomic, readonly) id object;
/// Subclasses can override to provide a more useful description
@property (nonatomic, readonly) NSString *objectDescription;

/// @return \c YES if \c object is an instance of a class,
/// or \c NO if \c object is a class itself.
@property (nonatomic, readonly) BOOL objectIsInstance;

/// An index into the `classHierarchy` array.
///
/// This property determines which set of data comes out of the metadata arrays below
/// For example, \c properties contains the properties of the selected class scope,
/// while \c allProperties is an array of arrays where each array is a set of
/// properties for a class in the class hierarchy of the current object.
@property (nonatomic) NSInteger classScope;

@property (nonatomic, readonly) NSArray<NSArray<DSPProperty *> *> *allProperties;
@property (nonatomic, readonly) NSArray<DSPProperty *> *properties;

@property (nonatomic, readonly) NSArray<NSArray<DSPProperty *> *> *allClassProperties;
@property (nonatomic, readonly) NSArray<DSPProperty *> *classProperties;

@property (nonatomic, readonly) NSArray<NSArray<DSPIvar *> *> *allIvars;
@property (nonatomic, readonly) NSArray<DSPIvar *> *ivars;

@property (nonatomic, readonly) NSArray<NSArray<DSPMethod *> *> *allMethods;
@property (nonatomic, readonly) NSArray<DSPMethod *> *methods;

@property (nonatomic, readonly) NSArray<NSArray<DSPMethod *> *> *allClassMethods;
@property (nonatomic, readonly) NSArray<DSPMethod *> *classMethods;

@property (nonatomic, readonly) NSArray<Class> *classHierarchyClasses;
@property (nonatomic, readonly) NSArray<DSPStaticMetadata *> *classHierarchy;

@property (nonatomic, readonly) NSArray<NSArray<DSPProtocol *> *> *allConformedProtocols;
@property (nonatomic, readonly) NSArray<DSPProtocol *> *conformedProtocols;

@property (nonatomic, readonly) NSArray<DSPStaticMetadata *> *allInstanceSizes;
@property (nonatomic, readonly) DSPStaticMetadata *instanceSize;

@property (nonatomic, readonly) NSArray<DSPStaticMetadata *> *allImageNames;
@property (nonatomic, readonly) DSPStaticMetadata *imageName;

- (void)reloadMetadata;
- (void)reloadClassHierarchy;

@end


@interface DSPObjectExplorer (SwiftMirrorAvailability)

/// Do not enable this property manually; the Swift mirror will flip the switch when it is loaded.
/// If you wish, you may \e disable it manually.
@property (nonatomic, class) BOOL swiftMirrorAvailable;

@end
