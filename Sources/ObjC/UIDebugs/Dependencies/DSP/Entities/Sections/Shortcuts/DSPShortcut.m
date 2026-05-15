#import "DSPShortcut.h"
#import "DSPProperty.h"
#import "DSPPropertyAttributes.h"
#import "DSPIvar.h"
#import "DSPMethod.h"
#import "DSPRuntime+UIKitHelpers.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPFieldEditorViewController.h"
#import "DSPMethodCallingViewController.h"
#import "DSPMetadataSection.h"
#import "DSPTableView.h"


#pragma mark - DSPShortcut

@interface DSPShortcut () {
    id _item;
}

@property (nonatomic, readonly) DSPMetadataKind metadataKind;
@property (nonatomic, readonly) DSPProperty *property;
@property (nonatomic, readonly) DSPMethod *method;
@property (nonatomic, readonly) DSPIvar *ivar;
@property (nonatomic, readonly) id<DSPRuntimeMetadata> metadata;
@end

@implementation DSPShortcut
@synthesize defaults = _defaults;

+ (id<DSPShortcut>)shortcutFor:(id)item {
    if ([item conformsToProtocol:@protocol(DSPShortcut)]) {
        return item;
    }
    
    DSPShortcut *shortcut = [self new];
    shortcut->_item = item;

    if ([item isKindOfClass:[DSPProperty class]]) {
        if (shortcut.property.isClassProperty) {
            shortcut->_metadataKind =  DSPMetadataKindClassProperties;
        } else {
            shortcut->_metadataKind =  DSPMetadataKindProperties;
        }
    }
    if ([item isKindOfClass:[DSPIvar class]]) {
        shortcut->_metadataKind = DSPMetadataKindIvars;
    }
    if ([item isKindOfClass:[DSPMethod class]]) {
        // We don't care if it's a class method or not
        shortcut->_metadataKind = DSPMetadataKindMethods;
    }

    return shortcut;
}

- (id)propertyOrIvarValue:(id)object {
    return [self.metadata currentValueWithTarget:object];
}

- (NSString *)titleWith:(id)object {
    switch (self.metadataKind) {
        case DSPMetadataKindClassProperties:
        case DSPMetadataKindProperties:
            // Since we're outside of the "properties" section, prepend @property for clarity.
            return [@"@property " stringByAppendingString:[_item description]];

        default:
            return [_item description];
    }

    NSAssert(
        [_item isKindOfClass:[NSString class]],
        @"Unexpected type: %@", [_item class]
    );

    return _item;
}

- (NSString *)subtitleWith:(id)object {
    if (self.metadataKind) {
        return [self.metadata previewWithTarget:object];
    }

    // Item is probably a string; must return empty string since
    // these will be gathered into an array. If the object is a
    // just a string, it doesn't get a subtitle.
    return @"";
}

- (void (^)(UIViewController *))didSelectActionWith:(id)object { 
    return nil;
}

- (UIViewController *)viewerWith:(id)object {
    NSAssert(self.metadataKind, @"Static titles cannot be viewed");
    return [self.metadata viewerWithTarget:object];
}

- (UIViewController *)editorWith:(id)object forSection:(DSPTableViewSection *)section {
    NSAssert(self.metadataKind, @"Static titles cannot be edited");
    return [self.metadata editorWithTarget:object section:section];
}

- (UITableViewCellAccessoryType)accessoryTypeWith:(id)object {
    if (self.metadataKind) {
        return [self.metadata suggestedAccessoryTypeWithTarget:object];
    }

    return UITableViewCellAccessoryNone;
}

- (NSString *)customReuseIdentifierWith:(id)object {
    if (self.metadataKind) {
        return kDSPCodeFontCell;
    }

    return kDSPMultilineCell;
}

#pragma mark DSPObjectExplorerDefaults

- (void)setDefaults:(DSPObjectExplorerDefaults *)defaults {
    _defaults = defaults;
    
    if (_metadataKind) {
        self.metadata.defaults = defaults;
    }
}

- (BOOL)isEditable {
    if (_metadataKind) {
        return self.metadata.isEditable;
    }
    
    return NO;
}

- (BOOL)isCallable {
    if (_metadataKind) {
        return self.metadata.isCallable;
    }
    
    return NO;
}

#pragma mark - Helpers

- (DSPProperty *)property { return _item; }
- (DSPMethodBase *)method { return _item; }
- (DSPIvar *)ivar { return _item; }
- (id<DSPRuntimeMetadata>)metadata { return _item; }

@end


#pragma mark - DSPActionShortcut

@interface DSPActionShortcut ()
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSString *(^subtitleFuture)(id);
@property (nonatomic, readonly) UIViewController *(^viewerFuture)(id);
@property (nonatomic, readonly) void (^selectionHandler)(UIViewController *, id);
@property (nonatomic, readonly) UITableViewCellAccessoryType (^accessoryTypeFuture)(id);
@end

@implementation DSPActionShortcut
@synthesize defaults = _defaults;

+ (instancetype)title:(NSString *)title
             subtitle:(NSString *(^)(id))subtitle
               viewer:(UIViewController *(^)(id))viewer
        accessoryType:(UITableViewCellAccessoryType (^)(id))type {
    return [[self alloc] initWithTitle:title subtitle:subtitle viewer:viewer selectionHandler:nil accessoryType:type];
}

+ (instancetype)title:(NSString *)title
             subtitle:(NSString * (^)(id))subtitle
     selectionHandler:(void (^)(UIViewController *, id))tapAction
        accessoryType:(UITableViewCellAccessoryType (^)(id))type {
    return [[self alloc] initWithTitle:title subtitle:subtitle viewer:nil selectionHandler:tapAction accessoryType:type];
}

- (id)initWithTitle:(NSString *)title
           subtitle:(id)subtitleFuture
             viewer:(id)viewerFuture
   selectionHandler:(id)tapAction
      accessoryType:(id)accessoryTypeFuture {
    NSParameterAssert(title.length);

    self = [super init];
    if (self) {
        id nilBlock = ^id (id obj) { return nil; };
        
        _title = title;
        _subtitleFuture = subtitleFuture ?: nilBlock;
        _viewerFuture = viewerFuture ?: nilBlock;
        _selectionHandler = tapAction;
        _accessoryTypeFuture = accessoryTypeFuture ?: nilBlock;
    }

    return self;
}

- (NSString *)titleWith:(id)object {
    return self.title;
}

- (NSString *)subtitleWith:(id)object {
    if (self.defaults.wantsDynamicPreviews) {
        return self.subtitleFuture(object);
    }
    
    return nil;
}

- (void (^)(UIViewController *))didSelectActionWith:(id)object {
    if (self.selectionHandler) {
        return ^(UIViewController *host) {
            self.selectionHandler(host, object);
        };
    }
    
    return nil;
}

- (UIViewController *)viewerWith:(id)object {
    return self.viewerFuture(object);
}

- (UITableViewCellAccessoryType)accessoryTypeWith:(id)object {
    return self.accessoryTypeFuture(object);
}

- (NSString *)customReuseIdentifierWith:(id)object {
    if (!self.subtitleFuture(object)) {
        // The text is more centered with this style if there is no subtitle
        return kDSPDefaultCell;
    }

    return nil;
}

- (BOOL)isEditable { return NO; }
- (BOOL)isCallable { return NO; }

@end
