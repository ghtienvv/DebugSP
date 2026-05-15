#import "DSPCollectionContentSection.h"
#import "DSPUtility.h"
#import "DSPRuntimeUtility.h"
#import "DSPSubtitleTableViewCell.h"
#import "DSPTableView.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPDefaultEditorViewController.h"

typedef NS_ENUM(NSUInteger, DSPCollectionType) {
    DSPUnsupportedCollection,
    DSPOrderedCollection,
    DSPUnorderedCollection,
    DSPKeyedCollection
};

@interface NSArray (DSPCollection) <DSPCollection> @end
@interface NSSet (DSPCollection) <DSPCollection> @end
@interface NSOrderedSet (DSPCollection) <DSPCollection> @end
@interface NSDictionary (DSPCollection) <DSPCollection> @end

@interface NSMutableArray (DSPMutableCollection) <DSPMutableCollection> @end
@interface NSMutableSet (DSPMutableCollection) <DSPMutableCollection> @end
@interface NSMutableOrderedSet (DSPMutableCollection) <DSPMutableCollection> @end
@interface NSMutableDictionary (DSPMutableCollection) <DSPMutableCollection>
- (void)filterUsingPredicate:(NSPredicate *)predicate;
@end

@interface DSPCollectionContentSection ()
/// Generated from \c collectionFuture or \c collection
@property (nonatomic, copy) id<DSPCollection> cachedCollection;
/// A static collection to display
@property (nonatomic, readonly) id<DSPCollection> collection;
/// A collection that may change over time and can be called upon for new data
@property (nonatomic, readonly) DSPCollectionContentFuture collectionFuture;
@property (nonatomic, readonly) DSPCollectionType collectionType;
@property (nonatomic, readonly) BOOL isMutable;
@end

@implementation DSPCollectionContentSection
@synthesize filterText = _filterText;

#pragma mark Initialization

+ (instancetype)forObject:(id)object {
    return [self forCollection:object];
}

+ (id)forCollection:(id<DSPCollection>)collection {
    DSPCollectionContentSection *section = [self new];
    section->_collectionType = [self typeForCollection:collection];
    section->_collection = collection;
    section.cachedCollection = collection;
    section->_isMutable = [collection respondsToSelector:@selector(filterUsingPredicate:)];
    return section;
}

+ (id)forReusableFuture:(DSPCollectionContentFuture)collectionFuture {
    DSPCollectionContentSection *section = [self new];
    section->_collectionFuture = collectionFuture;
    section.cachedCollection = (id<DSPCollection>)collectionFuture(section);
    section->_collectionType = [self typeForCollection:section.cachedCollection];
    section->_isMutable = [section->_cachedCollection respondsToSelector:@selector(filterUsingPredicate:)];
    return section;
}


#pragma mark - Misc

+ (DSPCollectionType)typeForCollection:(id<DSPCollection>)collection {
    // Order matters here, as NSDictionary is keyed but it responds to allObjects
    if ([collection respondsToSelector:@selector(objectAtIndex:)]) {
        return DSPOrderedCollection;
    }
    if ([collection respondsToSelector:@selector(objectForKey:)]) {
        return DSPKeyedCollection;
    }
    if ([collection respondsToSelector:@selector(allObjects)]) {
        return DSPUnorderedCollection;
    }

    [NSException raise:NSInvalidArgumentException
                format:@"Given collection does not properly conform to DSPCollection"];
    return DSPUnsupportedCollection;
}

/// Row titles
/// - Ordered: the index
/// - Unordered: the object
/// - Keyed: the key
- (NSString *)titleForRow:(NSInteger)row {
    switch (self.collectionType) {
        case DSPOrderedCollection:
            if (!self.hideOrderIndexes) {
                return @(row).stringValue;
            }
            // Fall-through
        case DSPUnorderedCollection:
            return [self describe:[self objectForRow:row]];
        case DSPKeyedCollection:
            return [self describe:self.cachedCollection.allKeys[row]];

        case DSPUnsupportedCollection:
            return nil;
    }
}

/// Row subtitles
/// - Ordered: the object
/// - Unordered: nothing
/// - Keyed: the value
- (NSString *)subtitleForRow:(NSInteger)row {
    switch (self.collectionType) {
        case DSPOrderedCollection:
            if (!self.hideOrderIndexes) {
                nil;
            }
            // Fall-through
        case DSPKeyedCollection:
            return [self describe:[self objectForRow:row]];
        case DSPUnorderedCollection:
            return nil;

        case DSPUnsupportedCollection:
            return nil;
    }
}

- (NSString *)describe:(id)object {
    return [DSPRuntimeUtility summaryForObject:object];
}

- (id)objectForRow:(NSInteger)row {
    switch (self.collectionType) {
        case DSPOrderedCollection:
            return self.cachedCollection[row];
        case DSPUnorderedCollection:
            return self.cachedCollection.allObjects[row];
        case DSPKeyedCollection:
            return self.cachedCollection[self.cachedCollection.allKeys[row]];

        case DSPUnsupportedCollection:
            return nil;
    }
}

- (UITableViewCellAccessoryType)accessoryTypeForRow:(NSInteger)row {
    return UITableViewCellAccessoryDisclosureIndicator;
//    return self.isMutable ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryDisclosureIndicator;
}


#pragma mark - Overrides

- (NSString *)title {
    if (!self.hideSectionTitle) {
        if (self.customTitle) {
            return self.customTitle;
        }
        
        return DSPPluralString(self.cachedCollection.count, @"Entries", @"Entry");
    }
    
    return nil;
}

- (NSInteger)numberOfRows {
    return self.cachedCollection.count;
}

- (void)setFilterText:(NSString *)filterText {
    super.filterText = filterText;
    
    if (filterText.length) {
        BOOL (^matcher)(id, id) = self.customFilter ?: ^BOOL(NSString *query, id obj) {
            return [[self describe:obj] localizedCaseInsensitiveContainsString:query];
        };
        
        NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
            return matcher(filterText, obj);
        }];
        
        id<DSPMutableCollection> tmp = self.cachedCollection.mutableCopy;
        [tmp filterUsingPredicate:filter];
        self.cachedCollection = tmp;
    } else {
        self.cachedCollection = self.collection ?: (id<DSPCollection>)self.collectionFuture(self);
    }
}

- (void)reloadData {
    if (self.collectionFuture) {
        self.cachedCollection = (id<DSPCollection>)self.collectionFuture(self);
    } else {
        self.cachedCollection = self.collection.copy;
    }
}

- (BOOL)canSelectRow:(NSInteger)row {
    return YES;
}

- (UIViewController *)viewControllerToPushForRow:(NSInteger)row {
    return [DSPObjectExplorerFactory explorerViewControllerForObject:[self objectForRow:row]];
}

- (NSString *)reuseIdentifierForRow:(NSInteger)row {
    return kDSPDetailCell;
}

- (void)configureCell:(__kindof DSPTableViewCell *)cell forRow:(NSInteger)row {
    cell.titleLabel.text = [self titleForRow:row];
    cell.subtitleLabel.text = [self subtitleForRow:row];
    cell.accessoryType = [self accessoryTypeForRow:row];
}

@end


#pragma mark - NSMutableDictionary

@implementation NSMutableDictionary (DSPMutableCollection)

- (void)filterUsingPredicate:(NSPredicate *)predicate {
    id test = ^BOOL(id key, NSUInteger idx, BOOL *stop) {
        if ([predicate evaluateWithObject:key]) {
            return NO;
        }
        
        return ![predicate evaluateWithObject:self[key]];
    };
    
    NSArray *keys = self.allKeys;
    NSIndexSet *remove = [keys indexesOfObjectsPassingTest:test];
    
    [self removeObjectsForKeys:[keys objectsAtIndexes:remove]];
}

@end
