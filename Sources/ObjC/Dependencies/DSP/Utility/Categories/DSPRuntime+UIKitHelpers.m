#import "DSPRuntime+UIKitHelpers.h"
#import "DSPRuntimeUtility.h"
#import "DSPPropertyAttributes.h"
#import "DSPArgumentInputViewFactory.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPFieldEditorViewController.h"
#import "DSPMethodCallingViewController.h"
#import "DSPObjectListViewController.h"
#import "DSPTableView.h"
#import "DSPUtility.h"
#import "NSArray+DSP.h"
#import "NSString+DSP.h"

#define DSPObjectExplorerDefaultsImpl \
- (DSPObjectExplorerDefaults *)defaults { \
    return self.tag; \
} \
 \
- (void)setDefaults:(DSPObjectExplorerDefaults *)defaults { \
    self.tag = defaults; \
}

#pragma mark DSPProperty
@implementation DSPProperty (UIKitHelpers)
DSPObjectExplorerDefaultsImpl

/// Decide whether to use potentialTarget or [potentialTarget class] to get or set property
- (id)appropriateTargetForPropertyType:(id)potentialTarget {
    if (!object_isClass(potentialTarget)) {
        if (self.isClassProperty) {
            return [potentialTarget class];
        } else {
            return potentialTarget;
        }
    } else {
        if (self.isClassProperty) {
            return potentialTarget;
        } else {
            // Instance property with a class object
            return nil;
        }
    }
}

- (BOOL)isEditable {
    if (self.attributes.isReadOnly) {
        return self.likelySetterExists;
    }
    
    const DSPTypeEncoding *typeEncoding = self.attributes.typeEncoding.UTF8String;
    return [DSPArgumentInputViewFactory canEditFieldWithTypeEncoding:typeEncoding currentValue:nil];
}

- (BOOL)isCallable {
    return YES;
}

- (id)currentValueWithTarget:(id)object {
    return [self getPotentiallyUnboxedValue:
        [self appropriateTargetForPropertyType:object]
    ];
}

- (id)currentValueBeforeUnboxingWithTarget:(id)object {
    return [self getValue:
        [self appropriateTargetForPropertyType:object]
    ];
}

- (NSString *)previewWithTarget:(id)object {
    if (object_isClass(object) && !self.isClassProperty) {
        return self.attributes.fullDeclaration;
    } else if (self.defaults.wantsDynamicPreviews) {
        return [DSPRuntimeUtility
            summaryForObject:[self currentValueWithTarget:object]
        ];
    }
    
    return nil;
}

- (UIViewController *)viewerWithTarget:(id)object {
    id value = [self currentValueWithTarget:object];
    return [DSPObjectExplorerFactory explorerViewControllerForObject:value];
}

- (UIViewController *)editorWithTarget:(id)object section:(DSPTableViewSection *)section {
    id target = [self appropriateTargetForPropertyType:object];
    return [DSPFieldEditorViewController target:target property:self commitHandler:^{
        [section reloadData:YES];
    }];
}

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    id targetForValueCheck = [self appropriateTargetForPropertyType:object];
    if (!targetForValueCheck) {
        // Instance property with a class object
        return UITableViewCellAccessoryNone;
    }

    // We use .tag to store the cached value of .isEditable that is
    // initialized by DSPObjectExplorer in -reloadMetada
    if ([self getPotentiallyUnboxedValue:targetForValueCheck]) {
        if (self.defaults.isEditable) {
            // Editable non-nil value, both
            return UITableViewCellAccessoryDetailDisclosureButton;
        } else {
            // Uneditable non-nil value, chevron only
            return UITableViewCellAccessoryDisclosureIndicator;
        }
    } else {
        if (self.defaults.isEditable) {
            // Editable nil value, just (i)
            return UITableViewCellAccessoryDetailButton;
        } else {
            // Non-editable nil value, neither
            return UITableViewCellAccessoryNone;
        }
    }
}

- (NSString *)reuseIdentifierWithTarget:(id)object { return nil; }

- (NSArray<UIAction *> *)additionalActionsWithTarget:(id)object sender:(UIViewController *)sender __IOS_AVAILABLE(13.0) {
    BOOL returnsObject = self.attributes.typeEncoding.dsp_typeIsObjectOrClass;
    BOOL targetNotNil = [self appropriateTargetForPropertyType:object] != nil;
    
    // "Explore PropertyClass" for properties with a concrete class name
    if (returnsObject) {
        NSMutableArray<UIAction *> *actions = [NSMutableArray new];
        
        // Action for exploring class of this property
        Class propertyClass = self.attributes.typeEncoding.dsp_typeClass;
        if (propertyClass) {
            NSString *title = [NSString stringWithFormat:@"Explore %@", NSStringFromClass(propertyClass)];
            [actions addObject:[UIAction actionWithTitle:title image:nil identifier:nil handler:^(UIAction *action) {
                UIViewController *explorer = [DSPObjectExplorerFactory explorerViewControllerForObject:propertyClass];
                [sender.navigationController pushViewController:explorer animated:YES];
            }]];
        }
        
        // Action for exploring references to this object
        if (targetNotNil) {
            // Since the property holder is not nil, check if the property value is nil
            id value = [self currentValueBeforeUnboxingWithTarget:object];
            if (value) {
                NSString *title = @"List all references";
                [actions addObject:[UIAction actionWithTitle:title image:nil identifier:nil handler:^(UIAction *action) {
                    UIViewController *list = [DSPObjectListViewController
                        objectsWithReferencesToObject:value
                        retained:NO
                    ];
                    [sender.navigationController pushViewController:list animated:YES];
                }]];
            }
        }
        
        return actions;
    }
    
    return nil;
}

- (NSArray<NSString *> *)copiableMetadataWithTarget:(id)object {
    BOOL returnsObject = self.attributes.typeEncoding.dsp_typeIsObjectOrClass;
    BOOL targetNotNil = [self appropriateTargetForPropertyType:object] != nil;
    
    NSMutableArray *items = [NSMutableArray arrayWithArray:@[
        @"Name",                      self.name ?: @"",
        @"Type",                      self.attributes.typeEncoding ?: @"",
        @"Declaration",               self.fullDescription ?: @"",
    ]];
    
    if (targetNotNil) {
        id value = [self currentValueBeforeUnboxingWithTarget:object];
        [items addObjectsFromArray:@[
            @"Value Preview",         [self previewWithTarget:object] ?: @"",
            @"Value Address",         returnsObject ? [DSPUtility addressOfObject:value] : @"",
        ]];
    }
    
    [items addObjectsFromArray:@[
        @"Getter",                    NSStringFromSelector(self.likelyGetter) ?: @"",
        @"Setter",                    self.likelySetterExists ? NSStringFromSelector(self.likelySetter) : @"",
        @"Image Name",                self.imageName ?: @"",
        @"Attributes",                self.attributes.string ?: @"",
        @"objc_property",             [DSPUtility pointerToString:self.objc_property],
        @"objc_property_attribute_t", [DSPUtility pointerToString:self.attributes.list],
    ]];
    
    return items;
}

- (NSString *)contextualSubtitleWithTarget:(id)object {
    id target = [self appropriateTargetForPropertyType:object];
    if (target && self.attributes.typeEncoding.dsp_typeIsObjectOrClass) {
        return [DSPUtility addressOfObject:[self currentValueBeforeUnboxingWithTarget:target]];
    }
    
    return nil;
}

@end


#pragma mark DSPIvar
@implementation DSPIvar (UIKitHelpers)
DSPObjectExplorerDefaultsImpl

- (BOOL)isEditable {
    const DSPTypeEncoding *typeEncoding = self.typeEncoding.UTF8String;
    return [DSPArgumentInputViewFactory canEditFieldWithTypeEncoding:typeEncoding currentValue:nil];
}

- (BOOL)isCallable {
    return NO;
}

- (id)currentValueWithTarget:(id)object {
    if (!object_isClass(object)) {
        return [self getPotentiallyUnboxedValue:object];
    }

    return nil;
}

- (NSString *)previewWithTarget:(id)object {
    if (object_isClass(object)) {
        return self.details;
    } else if (self.defaults.wantsDynamicPreviews) {
        return [DSPRuntimeUtility
            summaryForObject:[self currentValueWithTarget:object]
        ];
    }
    
    return nil;
}

- (UIViewController *)viewerWithTarget:(id)object {
    NSAssert(!object_isClass(object), @"Unreachable state: viewing ivar on class object");
    id value = [self currentValueWithTarget:object];
    return [DSPObjectExplorerFactory explorerViewControllerForObject:value];
}

- (UIViewController *)editorWithTarget:(id)object section:(DSPTableViewSection *)section {
    NSAssert(!object_isClass(object), @"Unreachable state: editing ivar on class object");
    return [DSPFieldEditorViewController target:object ivar:self commitHandler:^{
        [section reloadData:YES];
    }];
}

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    if (object_isClass(object)) {
        return UITableViewCellAccessoryNone;
    }

    // Could use .isEditable here, but we use .tag for speed since it is cached
    if ([self getPotentiallyUnboxedValue:object]) {
        if (self.defaults.isEditable) {
            // Editable non-nil value, both
            return UITableViewCellAccessoryDetailDisclosureButton;
        } else {
            // Uneditable non-nil value, chevron only
            return UITableViewCellAccessoryDisclosureIndicator;
        }
    } else {
        if (self.defaults.isEditable) {
            // Editable nil value, just (i)
            return UITableViewCellAccessoryDetailButton;
        } else {
            // Non-editable nil value, neither
            return UITableViewCellAccessoryNone;
        }
    }
}

- (NSString *)reuseIdentifierWithTarget:(id)object { return nil; }

- (NSArray<UIAction *> *)additionalActionsWithTarget:(id)object sender:(UIViewController *)sender __IOS_AVAILABLE(13.0) {
    Class ivarClass = self.typeEncoding.dsp_typeClass;
    
    // "Explore PropertyClass" for properties with a concrete class name
    if (ivarClass) {
        NSString *title = [NSString stringWithFormat:@"Explore %@", NSStringFromClass(ivarClass)];
        return @[[UIAction actionWithTitle:title image:nil identifier:nil handler:^(UIAction *action) {
            UIViewController *explorer = [DSPObjectExplorerFactory explorerViewControllerForObject:ivarClass];
            [sender.navigationController pushViewController:explorer animated:YES];
        }]];
    }
    
    return nil;
}

- (NSArray<NSString *> *)copiableMetadataWithTarget:(id)object {
    BOOL isInstance = !object_isClass(object);
    BOOL returnsObject = self.typeEncoding.dsp_typeIsObjectOrClass;
    id value = isInstance ? [self getValue:object] : nil;
    
    NSMutableArray *items = [NSMutableArray arrayWithArray:@[
        @"Name",          self.name ?: @"",
        @"Type",          self.typeEncoding ?: @"",
        @"Declaration",   self.description ?: @"",
    ]];
    
    if (isInstance) {
        [items addObjectsFromArray:@[
            @"Value Preview", isInstance ? [self previewWithTarget:object] : @"",
            @"Value Address", returnsObject ? [DSPUtility addressOfObject:value] : @"",
        ]];
    }
    
    [items addObjectsFromArray:@[
        @"Size",          @(self.size).stringValue,
        @"Offset",        @(self.offset).stringValue,
        @"objc_ivar",     [DSPUtility pointerToString:self.objc_ivar],
    ]];
    
    return items;
}

- (NSString *)contextualSubtitleWithTarget:(id)object {
    if (!object_isClass(object) && self.typeEncoding.dsp_typeIsObjectOrClass) {
        return [DSPUtility addressOfObject:[self getValue:object]];
    }
    
    return nil;
}

@end


#pragma mark DSPMethod
@implementation DSPMethodBase (UIKitHelpers)
DSPObjectExplorerDefaultsImpl

- (BOOL)isEditable {
    return NO;
}

- (BOOL)isCallable {
    return NO;
}

- (id)currentValueWithTarget:(id)object {
    // Methods can't be "edited" and have no "value"
    return nil;
}

- (NSString *)previewWithTarget:(id)object {
    return [self.selectorString stringByAppendingFormat:@"  —  %@", self.typeEncoding];
}

- (UIViewController *)viewerWithTarget:(id)object {
    // We disallow calling of DSPMethodBase methods
    @throw NSInternalInconsistencyException;
    return nil;
}

- (UIViewController *)editorWithTarget:(id)object section:(DSPTableViewSection *)section {
    // Methods cannot be edited
    @throw NSInternalInconsistencyException;
    return nil;
}

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    // We shouldn't be using any DSPMethodBase objects for this
    @throw NSInternalInconsistencyException;
    return UITableViewCellAccessoryNone;
}

- (NSString *)reuseIdentifierWithTarget:(id)object { return nil; }

- (NSArray<UIAction *> *)additionalActionsWithTarget:(id)object sender:(UIViewController *)sender __IOS_AVAILABLE(13.0) {
    return nil;
}

- (NSArray<NSString *> *)copiableMetadataWithTarget:(id)object {
    return @[
        @"Selector",      self.name ?: @"",
        @"Type Encoding", self.typeEncoding ?: @"",
        @"Declaration",   self.description ?: @"",
    ];
}

- (NSString *)contextualSubtitleWithTarget:(id)object {
    return nil;
}

@end

@implementation DSPMethod (UIKitHelpers)

- (BOOL)isCallable {
    return self.signature != nil;
}

- (UIViewController *)viewerWithTarget:(id)object {
    object = self.isInstanceMethod ? object : (object_isClass(object) ? object : [object class]);
    return [DSPMethodCallingViewController target:object method:self];
}

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    if (self.isInstanceMethod) {
        if (object_isClass(object)) {
            // Instance method from class, can't call
            return UITableViewCellAccessoryNone;
        } else {
            // Instance method from instance, can call
            return UITableViewCellAccessoryDisclosureIndicator;
        }
    } else {
        return UITableViewCellAccessoryDisclosureIndicator;
    }
}

- (NSArray<NSString *> *)copiableMetadataWithTarget:(id)object {
    return [[super copiableMetadataWithTarget:object] arrayByAddingObjectsFromArray:@[
        @"NSMethodSignature *", [DSPUtility addressOfObject:self.signature],
        @"Signature String",    self.signatureString ?: @"",
        @"Number of Arguments", @(self.numberOfArguments).stringValue,
        @"Return Type",         @(self.returnType ?: ""),
        @"Return Size",         @(self.returnSize).stringValue,
        @"objc_method",       [DSPUtility pointerToString:self.objc_method],
    ]];
}

@end


#pragma mark DSPProtocol
@implementation DSPProtocol (UIKitHelpers)
DSPObjectExplorerDefaultsImpl

- (BOOL)isEditable {
    return NO;
}

- (BOOL)isCallable {
    return NO;
}

- (id)currentValueWithTarget:(id)object {
    return nil;
}

- (NSString *)previewWithTarget:(id)object {
    return nil;
}

- (UIViewController *)viewerWithTarget:(id)object {
    return [DSPObjectExplorerFactory explorerViewControllerForObject:self];
}

- (UIViewController *)editorWithTarget:(id)object section:(DSPTableViewSection *)section {
    // Protocols cannot be edited
    @throw NSInternalInconsistencyException;
    return nil;
}

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    return UITableViewCellAccessoryDisclosureIndicator;
}

- (NSString *)reuseIdentifierWithTarget:(id)object { return nil; }

- (NSArray<UIAction *> *)additionalActionsWithTarget:(id)object sender:(UIViewController *)sender __IOS_AVAILABLE(13.0) {
    return nil;
}

- (NSArray<NSString *> *)copiableMetadataWithTarget:(id)object {
    NSArray<NSString *> *conformanceNames = [self.protocols valueForKeyPath:@"name"];
    NSString *conformances = [conformanceNames componentsJoinedByString:@"\n"];
    return @[
        @"Name",         self.name ?: @"",
        @"Conformances", conformances ?: @"",
    ];
}

- (NSString *)contextualSubtitleWithTarget:(id)object {
    return nil;
}

@end


#pragma mark DSPStaticMetadata
@interface DSPStaticMetadata () {
    @protected
    NSString *_name;
}
@property (nonatomic) DSPTableViewCellReuseIdentifier reuse;
@property (nonatomic) NSString *subtitle;
@property (nonatomic) id metadata;
@end

@interface DSPStaticMetadata_Class : DSPStaticMetadata
+ (instancetype)withClass:(Class)cls;
@end

@implementation DSPStaticMetadata
@synthesize name = _name;
@synthesize tag = _tag;

DSPObjectExplorerDefaultsImpl

+ (NSArray<DSPStaticMetadata *> *)classHierarchy:(NSArray<Class> *)classes {
    return [classes dsp_mapped:^id(Class cls, NSUInteger idx) {
        return [DSPStaticMetadata_Class withClass:cls];
    }];
}

+ (instancetype)style:(DSPStaticMetadataRowStyle)style title:(NSString *)title string:(NSString *)string {
    return [[self alloc] initWithStyle:style title:title subtitle:string];
}

+ (instancetype)style:(DSPStaticMetadataRowStyle)style title:(NSString *)title number:(NSNumber *)number {
    return [[self alloc] initWithStyle:style title:title subtitle:number.stringValue];
}

- (id)initWithStyle:(DSPStaticMetadataRowStyle)style title:(NSString *)title subtitle:(NSString *)subtitle  {
    self = [super init];
    if (self) {
        if (style == DSPStaticMetadataRowStyleKeyValue) {
            _reuse = kDSPKeyValueCell;
        } else {
            _reuse = kDSPMultilineDetailCell;
        }

        _name = title;
        _subtitle = subtitle;
    }

    return self;
}

- (NSString *)description {
    return self.name;
}

- (NSString *)reuseIdentifierWithTarget:(id)object {
    return self.reuse;
}

- (BOOL)isEditable {
    return NO;
}

- (BOOL)isCallable {
    return NO;
}

- (id)currentValueWithTarget:(id)object {
    return nil;
}

- (NSString *)previewWithTarget:(id)object {
    return self.subtitle;
}

- (UIViewController *)viewerWithTarget:(id)object {
    return nil;
}

- (UIViewController *)editorWithTarget:(id)object section:(DSPTableViewSection *)section {
    // Static metadata cannot be edited
    @throw NSInternalInconsistencyException;
    return nil;
}

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    return UITableViewCellAccessoryNone;
}

- (NSArray<UIAction *> *)additionalActionsWithTarget:(id)object sender:(UIViewController *)sender __IOS_AVAILABLE(13.0) {
    return nil;
}

- (NSArray<NSString *> *)copiableMetadataWithTarget:(id)object {
    return @[self.name, self.subtitle];
}

- (NSString *)contextualSubtitleWithTarget:(id)object {
    return nil;
}

@end


#pragma mark DSPStaticMetadata_Class
@implementation DSPStaticMetadata_Class

+ (instancetype)withClass:(Class)cls {
    NSParameterAssert(cls);
    
    DSPStaticMetadata_Class *metadata = [self new];
    metadata.metadata = cls;
    metadata->_name = NSStringFromClass(cls);
    metadata.reuse = kDSPDefaultCell;
    return metadata;
}

- (id)initWithStyle:(DSPStaticMetadataRowStyle)style title:(NSString *)title subtitle:(NSString *)subtitle {
    @throw NSInternalInconsistencyException;
    return nil;
}

- (UIViewController *)viewerWithTarget:(id)object {
    return [DSPObjectExplorerFactory explorerViewControllerForObject:self.metadata];
}

- (UITableViewCellAccessoryType)suggestedAccessoryTypeWithTarget:(id)object {
    return UITableViewCellAccessoryDisclosureIndicator;
}

- (NSArray<NSString *> *)copiableMetadataWithTarget:(id)object {
    return @[
        @"Class Name", self.name,
        @"Class", [DSPUtility addressOfObject:self.metadata]
    ];
}

- (NSString *)contextualSubtitleWithTarget:(id)object {
    return [DSPUtility addressOfObject:self.metadata];
}

@end
