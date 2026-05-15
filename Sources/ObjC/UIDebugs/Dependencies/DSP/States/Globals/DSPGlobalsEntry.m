#import "States/Globals/DSPGlobalsEntry.h"

@implementation DSPGlobalsEntry

+ (instancetype)entryWithEntry:(Class<DSPGlobalsEntry>)cls row:(DSPGlobalsRow)row {
    BOOL providesVCs = [cls respondsToSelector:@selector(globalsEntryViewController:)];
    BOOL providesActions = [cls respondsToSelector:@selector(globalsEntryRowAction:)];
    NSParameterAssert(cls);
    NSParameterAssert(providesVCs || providesActions);

    DSPGlobalsEntry *entry = [self new];
    entry->_entryNameFuture = ^{ return [cls globalsEntryTitle:row]; };

    if (providesVCs) {
        id action = providesActions ? [cls globalsEntryRowAction:row] : nil;
        if (action) {
            entry->_rowAction = action;
        } else {
            entry->_viewControllerFuture = ^{ return [cls globalsEntryViewController:row]; };
        }
    } else {
        entry->_rowAction = [cls globalsEntryRowAction:row];
    }

    return entry;
}

+ (instancetype)entryWithNameFuture:(DSPGlobalsEntryNameFuture)nameFuture
               viewControllerFuture:(DSPGlobalsEntryViewControllerFuture)viewControllerFuture {
    NSParameterAssert(nameFuture);
    NSParameterAssert(viewControllerFuture);

    DSPGlobalsEntry *entry = [self new];
    entry->_entryNameFuture = [nameFuture copy];
    entry->_viewControllerFuture = [viewControllerFuture copy];

    return entry;
}

+ (instancetype)entryWithNameFuture:(DSPGlobalsEntryNameFuture)nameFuture
                             action:(DSPGlobalsEntryRowAction)rowSelectedAction {
    NSParameterAssert(nameFuture);
    NSParameterAssert(rowSelectedAction);

    DSPGlobalsEntry *entry = [self new];
    entry->_entryNameFuture = [nameFuture copy];
    entry->_rowAction = [rowSelectedAction copy];

    return entry;
}

@end

@interface DSPGlobalsEntry (Debugging)
@property (nonatomic, readonly) NSString *name;
@end

@implementation DSPGlobalsEntry (Debugging)

- (NSString *)name {
    return self.entryNameFuture();
}

@end

#pragma mark - dsp_concreteGlobalsEntry

@implementation NSObject (DSPGlobalsEntry)

+ (DSPGlobalsEntry *)dsp_concreteGlobalsEntry:(DSPGlobalsRow)row {
    if ([self conformsToProtocol:@protocol(DSPGlobalsEntry)]) {
        return [DSPGlobalsEntry entryWithEntry:self row:row];
    }

    return nil;
}

@end
