#import "DSPTableViewSection.h"
#import "DSPObjectExplorer.h"

typedef NS_ENUM(NSUInteger, DSPMetadataKind) {
    DSPMetadataKindProperties = 1,
    DSPMetadataKindClassProperties,
    DSPMetadataKindIvars,
    DSPMetadataKindMethods,
    DSPMetadataKindClassMethods,
    DSPMetadataKindClassHierarchy,
    DSPMetadataKindProtocols,
    DSPMetadataKindOther
};

/// This section is used for displaying ObjC runtime metadata
/// about a class or object, such as listing methods, properties, etc.
@interface DSPMetadataSection : DSPTableViewSection

+ (instancetype)explorer:(DSPObjectExplorer *)explorer kind:(DSPMetadataKind)metadataKind;

@property (nonatomic, readonly) DSPMetadataKind metadataKind;

/// The names of metadata to exclude. Useful if you wish to group specific
/// properties or methods together in their own section outside of this one.
///
/// Setting this property calls \c reloadData on this section.
@property (nonatomic) NSSet<NSString *> *excludedMetadata;

@end
