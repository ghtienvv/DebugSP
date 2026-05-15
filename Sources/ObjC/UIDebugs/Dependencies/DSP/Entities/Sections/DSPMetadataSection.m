#import "DSPMetadataSection.h"
#import "DSPTableView.h"
#import "DSPTableViewCell.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPFieldEditorViewController.h"
#import "DSPMethodCallingViewController.h"
#import "DSPIvar.h"
#import "NSArray+DSP.h"
#import "DSPRuntime+UIKitHelpers.h"

@interface DSPMetadataSection ()
@property (nonatomic, readonly) DSPObjectExplorer *explorer;
/// Filtered
@property (nonatomic, copy) NSArray<id<DSPRuntimeMetadata>> *metadata;
/// Unfiltered
@property (nonatomic, copy) NSArray<id<DSPRuntimeMetadata>> *allMetadata;
@end

@implementation DSPMetadataSection

#pragma mark - Initialization

+ (instancetype)explorer:(DSPObjectExplorer *)explorer kind:(DSPMetadataKind)metadataKind {
    return [[self alloc] initWithExplorer:explorer kind:metadataKind];
}

- (id)initWithExplorer:(DSPObjectExplorer *)explorer kind:(DSPMetadataKind)metadataKind {
    self = [super init];
    if (self) {
        _explorer = explorer;
        _metadataKind = metadataKind;

        [self reloadData];
    }

    return self;
}

#pragma mark - Private

- (NSString *)titleWithBaseName:(NSString *)baseName {
    unsigned long totalCount = self.allMetadata.count;
    unsigned long filteredCount = self.metadata.count;

    if (totalCount == filteredCount) {
        return [baseName stringByAppendingFormat:@" (%lu)", totalCount];
    } else {
        return [baseName stringByAppendingFormat:@" (%lu of %lu)", filteredCount, totalCount];
    }
}

- (UITableViewCellAccessoryType)accessoryTypeForRow:(NSInteger)row {
    return [self.metadata[row] suggestedAccessoryTypeWithTarget:self.explorer.object];
}

#pragma mark - Public

- (void)setExcludedMetadata:(NSSet<NSString *> *)excludedMetadata {
    _excludedMetadata = excludedMetadata;
    [self reloadData];
}

#pragma mark - Overrides

- (NSString *)titleForRow:(NSInteger)row {
    return [self.metadata[row] description];
}

- (NSString *)subtitleForRow:(NSInteger)row {
    return [self.metadata[row] previewWithTarget:self.explorer.object];
}

- (NSString *)title {
    switch (self.metadataKind) {
        case DSPMetadataKindProperties:
            return [self titleWithBaseName:@"Properties"];
        case DSPMetadataKindClassProperties:
            return [self titleWithBaseName:@"Class Properties"];
        case DSPMetadataKindIvars:
            return [self titleWithBaseName:@"Ivars"];
        case DSPMetadataKindMethods:
            return [self titleWithBaseName:@"Methods"];
        case DSPMetadataKindClassMethods:
            return [self titleWithBaseName:@"Class Methods"];
        case DSPMetadataKindClassHierarchy:
            return [self titleWithBaseName:@"Class Hierarchy"];
        case DSPMetadataKindProtocols:
            return [self titleWithBaseName:@"Protocols"];
        case DSPMetadataKindOther:
            return @"Miscellaneous";
    }
}

- (NSInteger)numberOfRows {
    return self.metadata.count;
}

- (void)setFilterText:(NSString *)filterText {
    super.filterText = filterText;

    if (!self.filterText.length) {
        self.metadata = self.allMetadata;
    } else {
        self.metadata = [self.allMetadata dsp_filtered:^BOOL(id<DSPRuntimeMetadata> obj, NSUInteger idx) {
            return [obj.description localizedCaseInsensitiveContainsString:self.filterText];
        }];
    }
}

- (void)reloadData {
    switch (self.metadataKind) {
        case DSPMetadataKindProperties:
            self.allMetadata = self.explorer.properties;
            break;
        case DSPMetadataKindClassProperties:
            self.allMetadata = self.explorer.classProperties;
            break;
        case DSPMetadataKindIvars:
            self.allMetadata = self.explorer.ivars;
            break;
        case DSPMetadataKindMethods:
            self.allMetadata = self.explorer.methods;
            break;
        case DSPMetadataKindClassMethods:
            self.allMetadata = self.explorer.classMethods;
            break;
        case DSPMetadataKindProtocols:
            self.allMetadata = self.explorer.conformedProtocols;
            break;
        case DSPMetadataKindClassHierarchy:
            self.allMetadata = self.explorer.classHierarchy;
            break;
        case DSPMetadataKindOther:
            self.allMetadata = @[self.explorer.instanceSize, self.explorer.imageName];
            break;
    }

    // Remove excluded metadata
    if (self.excludedMetadata.count) {
        id filterBlock = ^BOOL(id<DSPRuntimeMetadata> obj, NSUInteger idx) {
            return ![self.excludedMetadata containsObject:obj.name];
        };

        // Filter exclusions and sort
        self.allMetadata = [[self.allMetadata dsp_filtered:filterBlock]
            sortedArrayUsingSelector:@selector(compare:)
        ];
    }

    // Re-filter data
    self.filterText = self.filterText;
}

- (BOOL)canSelectRow:(NSInteger)row {
    UITableViewCellAccessoryType accessory = [self accessoryTypeForRow:row];
    return accessory == UITableViewCellAccessoryDisclosureIndicator ||
        accessory == UITableViewCellAccessoryDetailDisclosureButton;
}

- (NSString *)reuseIdentifierForRow:(NSInteger)row {
    return [self.metadata[row] reuseIdentifierWithTarget:self.explorer.object] ?: kDSPCodeFontCell;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    return [self.metadata[row] viewerWithTarget:self.explorer.object];
}

- (void (^)(__kindof UIViewController *))didPressInfoButtonAction:(NSInteger)row {
    return ^(UIViewController *host) {
        [host.navigationController pushViewController:[self editorForRow:row] animated:YES];
    };
}

- (UIViewController *)editorForRow:(NSInteger)row {
    return [self.metadata[row] editorWithTarget:self.explorer.object section:self];
}

- (void)configureCell:(__kindof DSPTableViewCell *)cell forRow:(NSInteger)row {
    cell.titleLabel.text = [self titleForRow:row];
    cell.subtitleLabel.text = [self subtitleForRow:row];
    cell.accessoryType = [self accessoryTypeForRow:row];
}

- (NSString *)menuSubtitleForRow:(NSInteger)row {
    return [self.metadata[row] contextualSubtitleWithTarget:self.explorer.object];
}

- (NSArray<UIMenuElement *> *)menuItemsForRow:(NSInteger)row sender:(UIViewController *)sender {
    NSArray<UIMenuElement *> *existingItems = [super menuItemsForRow:row sender:sender];
    
    // These two metadata kinds don't any of the additional options below
    switch (self.metadataKind) {
        case DSPMetadataKindClassHierarchy:
        case DSPMetadataKindOther:
            return existingItems;
            
        default: break;
    }
    
    id<DSPRuntimeMetadata> metadata = self.metadata[row];
    NSMutableArray<UIMenuElement *> *menuItems = [NSMutableArray new];
    
    [menuItems addObject:[UIAction
        actionWithTitle:@"Explore Metadata"
        image:nil
        identifier:nil
        handler:^(__kindof UIAction *action) {
            [sender.navigationController pushViewController:[DSPObjectExplorerFactory
                explorerViewControllerForObject:metadata
            ] animated:YES];
        }
    ]];
    [menuItems addObjectsFromArray:[metadata
        additionalActionsWithTarget:self.explorer.object sender:sender
    ]];
    [menuItems addObjectsFromArray:existingItems];
    
    return menuItems.copy;
}

- (NSArray<NSString *> *)copyMenuItemsForRow:(NSInteger)row {
    return [self.metadata[row] copiableMetadataWithTarget:self.explorer.object];
}

@end
