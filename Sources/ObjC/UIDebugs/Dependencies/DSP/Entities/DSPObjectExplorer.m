#import "DSPObjectExplorer.h"
#import "DSPUtility.h"
#import "DSPRuntimeUtility.h"
#import "NSObject+DSP_Reflection.h"
#import "DSPRuntime+Compare.h"
#import "DSPRuntime+UIKitHelpers.h"
#import "DSPPropertyAttributes.h"
#import "DSPMetadataSection.h"
#import "NSUserDefaults+DSP.h"
#import "DSPMirror.h"
#import "DSPSwiftInternal.h"

@implementation DSPObjectExplorerDefaults

+ (instancetype)canEdit:(BOOL)editable wantsPreviews:(BOOL)showPreviews {
    DSPObjectExplorerDefaults *defaults = [self new];
    defaults->_isEditable = editable;
    defaults->_wantsDynamicPreviews = showPreviews;
    return defaults;
}

@end

@interface DSPObjectExplorer () {
    NSMutableArray<NSArray<DSPProperty *> *> *_allProperties;
    NSMutableArray<NSArray<DSPProperty *> *> *_allClassProperties;
    NSMutableArray<NSArray<DSPIvar *> *> *_allIvars;
    NSMutableArray<NSArray<DSPMethod *> *> *_allMethods;
    NSMutableArray<NSArray<DSPMethod *> *> *_allClassMethods;
    NSMutableArray<NSArray<DSPProtocol *> *> *_allConformedProtocols;
    NSMutableArray<DSPStaticMetadata *> *_allInstanceSizes;
    NSMutableArray<DSPStaticMetadata *> *_allImageNames;
    NSString *_objectDescription;
}

@property (nonatomic, readonly) id<DSPMirror> initialMirror;
@end

@implementation DSPObjectExplorer

+ (void)initialize {
    if (self == DSPObjectExplorer.class) {
        DSPObjectExplorer.swiftMirrorAvailable = NSClassFromString(@"DSPSwiftMirror") != nil;
    }
}

#pragma mark - Initialization

+ (id)forObject:(id)objectOrClass {
    return [[self alloc] initWithObject:objectOrClass];
}

- (id)initWithObject:(id)objectOrClass {
    NSParameterAssert(objectOrClass);
    
    self = [super init];
    if (self) {
        _object = objectOrClass;
        _objectIsInstance = !object_isClass(objectOrClass);
        
        [self reloadMetadata];
    }

    return self;
}

- (id<DSPMirror>)mirrorForClass:(Class)cls {
    static Class DSPSwiftMirror = nil;
    
    // Use the Swift mirror when it is available for Swift types.
    if (DSPIsSwiftObjectOrClass(cls) && DSPObjectExplorer.swiftMirrorAvailable) {
        // Initialize DSPSwiftMirror class if needed
        if (!DSPSwiftMirror) {
            DSPSwiftMirror = NSClassFromString(@"DSPSwiftMirror");            
        }
        
        return [(id<DSPMirror>)[DSPSwiftMirror alloc] initWithSubject:cls];
    }
    
    // No; not a Swift object, or the Swift mirror is unavailable.
    return [DSPMirror reflect:cls];
}


#pragma mark - Public

+ (void)configureDefaultsForItems:(NSArray<id<DSPObjectExplorerItem>> *)items {
    BOOL hidePreviews = NSUserDefaults.standardUserDefaults.dsp_explorerHidesVariablePreviews;
    DSPObjectExplorerDefaults *mutable = [DSPObjectExplorerDefaults
        canEdit:YES wantsPreviews:!hidePreviews
    ];
    DSPObjectExplorerDefaults *immutable = [DSPObjectExplorerDefaults
        canEdit:NO wantsPreviews:!hidePreviews
    ];

    // .tag is used to cache whether the value of .isEditable;
    // This could change at runtime so it is important that
    // it is cached every time shortcuts are requested and not
    // just once at as shortcuts are initially registered
    for (id<DSPObjectExplorerItem> metadata in items) {
        metadata.defaults = metadata.isEditable ? mutable : immutable;
    }
}

- (NSString *)objectDescription {
    if (!_objectDescription) {
        // Hard-code UIColor description
        if ([DSPRuntimeUtility safeObject:self.object isKindOfClass:[UIColor class]]) {
            CGFloat h, s, l, r, g, b, a;
            [self.object getRed:&r green:&g blue:&b alpha:&a];
            [self.object getHue:&h saturation:&s brightness:&l alpha:nil];

            return [NSString stringWithFormat:
                @"HSL: (%.3f, %.3f, %.3f)\nRGB: (%.3f, %.3f, %.3f)\nAlpha: %.3f",
                h, s, l, r, g, b, a
            ];
        }

        NSString *description = [DSPRuntimeUtility safeDescriptionForObject:self.object];

        if (!description.length) {
            NSString *address = [DSPUtility addressOfObject:self.object];
            return [NSString stringWithFormat:@"Object at %@ returned empty description", address];
        }
        
        if (description.length > 10000) {
            description = [description substringToIndex:10000];
        }

        _objectDescription = description;
    }

    return _objectDescription;
}

- (void)setClassScope:(NSInteger)classScope {
    _classScope = classScope;
    
    [self reloadScopedMetadata];
}

- (void)reloadMetadata {
    _allProperties = [NSMutableArray new];
    _allClassProperties = [NSMutableArray new];
    _allIvars = [NSMutableArray new];
    _allMethods = [NSMutableArray new];
    _allClassMethods = [NSMutableArray new];
    _allConformedProtocols = [NSMutableArray new];
    _allInstanceSizes = [NSMutableArray new];
    _allImageNames = [NSMutableArray new];
    _objectDescription = nil;

    [self reloadClassHierarchy];
    
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    BOOL hideBackingIvars = defaults.dsp_explorerHidesPropertyIvars;
    BOOL hidePropertyMethods = defaults.dsp_explorerHidesPropertyMethods;
    BOOL hidePrivateMethods = defaults.dsp_explorerHidesPrivateMethods;
    BOOL showMethodOverrides = defaults.dsp_explorerShowsMethodOverrides;
    
    NSMutableArray<NSArray<DSPProperty *> *> *allProperties = [NSMutableArray new];
    NSMutableArray<NSArray<DSPProperty *> *> *allClassProps = [NSMutableArray new];
    NSMutableArray<NSArray<DSPMethod *> *> *allMethods = [NSMutableArray new];
    NSMutableArray<NSArray<DSPMethod *> *> *allClassMethods = [NSMutableArray new];

    // Loop over each class and each superclass, collect
    // the fresh and unique metadata in each category
    Class superclass = nil;
    NSInteger count = self.classHierarchyClasses.count;
    NSInteger rootIdx = count - 1;
    for (NSInteger i = 0; i < count; i++) {
        Class cls = self.classHierarchyClasses[i];
        id<DSPMirror> mirror = [self mirrorForClass:cls];
        superclass = (i < rootIdx) ? self.classHierarchyClasses[i+1] : nil;

        [allProperties addObject:[self
            metadataUniquedByName:mirror.properties
            superclass:superclass
            kind:DSPMetadataKindProperties
            skip:showMethodOverrides
        ]];
        [allClassProps addObject:[self
            metadataUniquedByName:mirror.classProperties
            superclass:superclass
            kind:DSPMetadataKindClassProperties
            skip:showMethodOverrides
        ]];
        [_allIvars addObject:[self
            metadataUniquedByName:mirror.ivars
            superclass:nil
            kind:DSPMetadataKindIvars
            skip:NO
        ]];
        [allMethods addObject:[self
            metadataUniquedByName:mirror.methods
            superclass:superclass
            kind:DSPMetadataKindMethods
            skip:showMethodOverrides
        ]];
        [allClassMethods addObject:[self
            metadataUniquedByName:mirror.classMethods
            superclass:superclass
            kind:DSPMetadataKindClassMethods
            skip:showMethodOverrides
        ]];
        [_allConformedProtocols addObject:[self
            metadataUniquedByName:mirror.protocols
            superclass:superclass
            kind:DSPMetadataKindProtocols
            skip:NO
        ]];
        
        // TODO: join instance size, image name, and class hierarchy into a single model object
        // This would greatly reduce the laziness that has begun to manifest itself here
        [_allInstanceSizes addObject:[DSPStaticMetadata
            style:DSPStaticMetadataRowStyleKeyValue
            title:@"Instance Size" number:@(class_getInstanceSize(cls))
        ]];
        [_allImageNames addObject:[DSPStaticMetadata
            style:DSPStaticMetadataRowStyleDefault
            title:@"Image Name" string:@(class_getImageName(cls) ?: "Created at Runtime")
        ]];
    }
    
    _classHierarchy = [DSPStaticMetadata classHierarchy:self.classHierarchyClasses];
    
    NSArray<NSArray<DSPProperty *> *> *properties = allProperties;
    
    // Potentially filter property-backing ivars
    if (hideBackingIvars) {
        NSArray<NSArray<DSPIvar *> *> *ivars = _allIvars.copy;
        _allIvars = [ivars dsp_mapped:^id(NSArray<DSPIvar *> *list, NSUInteger idx) {
            // Get a set of all backing ivar names for the current class in the hierarchy
            NSSet *ivarNames = [NSSet setWithArray:({
                [properties[idx] dsp_mapped:^id(DSPProperty *p, NSUInteger idx) {
                    // Nil if no ivar, and array is flatted
                    return p.likelyIvarName;
                }];
            })];
            
            // Remove ivars whose name is in the ivar names list
            return [list dsp_filtered:^BOOL(DSPIvar *ivar, NSUInteger idx) {
                return ![ivarNames containsObject:ivar.name];
            }];
        }];
    }
    
    // Potentially filter property-backing methods
    if (hidePropertyMethods) {
        allMethods = [allMethods dsp_mapped:^id(NSArray<DSPMethod *> *list, NSUInteger idx) {
            // Get a set of all property method names for the current class in the hierarchy
            NSSet *methodNames = [NSSet setWithArray:({
                [properties[idx] dsp_flatmapped:^NSArray *(DSPProperty *p, NSUInteger idx) {
                    if (p.likelyGetterExists) {
                        if (p.likelySetterExists) {
                            return @[p.likelyGetterString, p.likelySetterString];
                        }
                        
                        return @[p.likelyGetterString];
                    } else if (p.likelySetterExists) {
                        return @[p.likelySetterString];
                    }
                    
                    return nil;
                }];
            })];
            
            // Remove methods whose name is in the property method names list
            return [list dsp_filtered:^BOOL(DSPMethod *method, NSUInteger idx) {
                return ![methodNames containsObject:method.selectorString];
            }];
        }];
    }
    
    if (hidePrivateMethods) {
        id methodMapBlock = ^id(NSArray<DSPMethod *> *list, NSUInteger idx) {
            // Remove methods which contain an underscore
            return [list dsp_filtered:^BOOL(DSPMethod *method, NSUInteger idx) {
                return ![method.selectorString containsString:@"_"];
            }];
        };
        id propertyMapBlock = ^id(NSArray<DSPProperty *> *list, NSUInteger idx) {
            // Remove methods which contain an underscore
            return [list dsp_filtered:^BOOL(DSPProperty *prop, NSUInteger idx) {
                return ![prop.name containsString:@"_"];
            }];
        };
        
        allMethods = [allMethods dsp_mapped:methodMapBlock];
        allClassMethods = [allClassMethods dsp_mapped:methodMapBlock];
        allProperties = [allProperties dsp_mapped:propertyMapBlock];
        allClassProps = [allClassProps dsp_mapped:propertyMapBlock];
    }
    
    _allProperties = allProperties;
    _allClassProperties = allClassProps;
    _allMethods = allMethods;
    _allClassMethods = allClassMethods;

    // Set up UIKit helper data
    // Really, we only need to call this on properties and ivars
    // because no other metadata types support editing.
    NSArray<NSArray *>*metadatas = @[
        _allProperties, _allClassProperties, _allIvars,
       /* _allMethods, _allClassMethods, _allConformedProtocols */
    ];
    for (NSArray *matrix in metadatas) {
        for (NSArray *metadataByClass in matrix) {
            [DSPObjectExplorer configureDefaultsForItems:metadataByClass];
        }
    }
    
    [self reloadScopedMetadata];
}


#pragma mark - Private

- (void)reloadScopedMetadata {
    _properties = self.allProperties[self.classScope];
    _classProperties = self.allClassProperties[self.classScope];
    _ivars = self.allIvars[self.classScope];
    _methods = self.allMethods[self.classScope];
    _classMethods = self.allClassMethods[self.classScope];
    _conformedProtocols = self.allConformedProtocols[self.classScope];
    _instanceSize = self.allInstanceSizes[self.classScope];
    _imageName = self.allImageNames[self.classScope];
}

/// Accepts an array of dsp metadata objects and discards objects
/// with duplicate names, as well as properties and methods which
/// aren't "new" (i.e. those which the superclass responds to)
- (NSArray *)metadataUniquedByName:(NSArray *)list
                        superclass:(Class)superclass
                              kind:(DSPMetadataKind)kind
                              skip:(BOOL)skipUniquing {
    if (skipUniquing) {
        return list;
    }
    
    // Remove items with same name and return filtered list
    NSMutableSet *names = [NSMutableSet new];
    return [list dsp_filtered:^BOOL(id obj, NSUInteger idx) {
        NSString *name = [obj name];
        if ([names containsObject:name]) {
            return NO;
        } else {
            if (!name) {
                return NO;
            }
            
            [names addObject:name];

            // Skip methods and properties which are just overrides,
            // potentially skip ivars and methods associated with properties
            switch (kind) {
                case DSPMetadataKindProperties:
                    if ([superclass instancesRespondToSelector:[obj likelyGetter]]) {
                        return NO;
                    }
                    break;
                case DSPMetadataKindClassProperties:
                    if ([superclass respondsToSelector:[obj likelyGetter]]) {
                        return NO;
                    }
                    break;
                case DSPMetadataKindMethods:
                    if ([superclass instancesRespondToSelector:NSSelectorFromString(name)]) {
                        return NO;
                    }
                    break;
                case DSPMetadataKindClassMethods:
                    if ([superclass respondsToSelector:NSSelectorFromString(name)]) {
                        return NO;
                    }
                    break;

                case DSPMetadataKindProtocols:
                case DSPMetadataKindClassHierarchy:
                case DSPMetadataKindOther:
                    return YES; // These types are already uniqued
                    break;
                    
                // Ivars cannot be overidden
                case DSPMetadataKindIvars: break;
            }

            return YES;
        }
    }];
}


#pragma mark - Superclasses

- (void)reloadClassHierarchy {
    // The class hierarchy will never contain metaclass objects by this logic;
    // it is always the same for a given class and instances of it
    _classHierarchyClasses = [[self.object class] dsp_classHierarchy];
}

@end


#pragma mark - Swift Mirror
@implementation DSPObjectExplorer (SwiftMirrorAvailability)
static BOOL _swiftMirrorAvailable = NO;

+ (BOOL)swiftMirrorAvailable { return _swiftMirrorAvailable; }
+ (void)setSwiftMirrorAvailable:(BOOL)enable { _swiftMirrorAvailable = enable; }

@end
