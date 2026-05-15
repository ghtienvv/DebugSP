#import "DSPObjectListViewController.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPObjectExplorerViewController.h"
#import "DSPMutableListSection.h"
#import "DSPRuntimeUtility.h"
#import "DSPUtility.h"
#import "DSPHeapEnumerator.h"
#import "DSPObjectRef.h"
#import "NSString+DSP.h"
#import "NSObject+DSP_Reflection.h"
#import "DSPTableViewCell.h"
#import <malloc/malloc.h>


typedef NS_ENUM(NSUInteger, DSPObjectReferenceSection) {
    DSPObjectReferenceSectionMain,
    DSPObjectReferenceSectionAutoLayout,
    DSPObjectReferenceSectionKVO,
    DSPObjectReferenceSectionDSP,
    
    DSPObjectReferenceSectionCount
};

@interface DSPObjectListViewController ()

@property (nonatomic, readonly, class) NSArray<NSPredicate *> *defaultPredicates;
@property (nonatomic, readonly, class) NSArray<NSString *> *defaultSectionTitles;


@property (nonatomic, copy) NSArray<DSPMutableListSection *> *sections;
@property (nonatomic, copy) NSArray<DSPMutableListSection *> *allSections;

@property (nonatomic, readonly, nullable) NSArray<DSPObjectRef *> *references;
@property (nonatomic, readonly) NSArray<NSPredicate *> *predicates;
@property (nonatomic, readonly) NSArray<NSString *> *sectionTitles;

@end

@implementation DSPObjectListViewController
@dynamic sections, allSections;

#pragma mark - Reference Grouping

+ (NSPredicate *)defaultPredicateForSection:(NSInteger)section {
    // These are the types of references that we typically don't care about.
    // We want this list of "object-ivar pairs" split into two sections.
    BOOL(^isKVORelated)(DSPObjectRef *, NSDictionary *) = ^BOOL(DSPObjectRef *ref, NSDictionary *bindings) {
        NSString *row = ref.reference;
        return [row isEqualToString:@"__NSObserver object"] ||
               [row isEqualToString:@"_CFXNotificationObjcObserverRegistration _object"];
    };

    /// These are common AutoLayout related references we also rarely care about.
    BOOL(^isConstraintRelated)(DSPObjectRef *, NSDictionary *) = ^BOOL(DSPObjectRef *ref, NSDictionary *bindings) {
        static NSSet *ignored = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            ignored = [NSSet setWithArray:@[
                @"NSLayoutConstraint _container",
                @"NSContentSizeLayoutConstraint _container",
                @"NSAutoresizingMaskLayoutConstraint _container",
                @"MASViewConstraint _installedView",
                @"MASLayoutConstraint _container",
                @"MASViewAttribute _view"
            ]];
        });

        NSString *row = ref.reference;
        return ([row hasPrefix:@"NSLayout"] && [row hasSuffix:@" _referenceItem"]) ||
               ([row hasPrefix:@"NSIS"] && [row hasSuffix:@" _delegate"])  ||
               ([row hasPrefix:@"_NSAutoresizingMask"] && [row hasSuffix:@" _referenceItem"]) ||
               [ignored containsObject:row];
    };
    
    /// These are DSP classes and usually you aren't looking for DSP references inside DSP itself
    BOOL(^isDSPClass)(DSPObjectRef *, NSDictionary *) = ^BOOL(DSPObjectRef *ref, NSDictionary *bindings) {
        return [ref.reference hasPrefix:@"DSP"];
    };

    BOOL(^isEssential)(DSPObjectRef *, NSDictionary *) = ^BOOL(DSPObjectRef *ref, NSDictionary *bindings) {
        return !(
            isKVORelated(ref, bindings) ||
            isConstraintRelated(ref, bindings) ||
            isDSPClass(ref, bindings)
        );
    };

    switch (section) {
        case DSPObjectReferenceSectionMain:
            return [NSPredicate predicateWithBlock:isEssential];
        case DSPObjectReferenceSectionAutoLayout:
            return [NSPredicate predicateWithBlock:isConstraintRelated];
        case DSPObjectReferenceSectionKVO:
            return [NSPredicate predicateWithBlock:isKVORelated];
        case DSPObjectReferenceSectionDSP:
            return [NSPredicate predicateWithBlock:isDSPClass];

        default: return nil;
    }
}

+ (NSArray<NSPredicate *> *)defaultPredicates {
    return [NSArray dsp_forEachUpTo:DSPObjectReferenceSectionCount map:^id(NSUInteger i) {
        return [self defaultPredicateForSection:i];
    }];
}

+ (NSArray<NSString *> *)defaultSectionTitles {
    return @[
        @"", @"AutoLayout", @"Key-Value Observing", @"DSP"
    ];
}


#pragma mark - Initialization

- (id)initWithReferences:(nullable NSArray<DSPObjectRef *> *)references {
    return [self initWithReferences:references predicates:nil sectionTitles:nil];
}

- (id)initWithReferences:(NSArray<DSPObjectRef *> *)references
              predicates:(NSArray<NSPredicate *> *)predicates
           sectionTitles:(NSArray<NSString *> *)sectionTitles {
    NSParameterAssert(predicates.count == sectionTitles.count);

    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _references = references;
        _predicates = predicates;
        _sectionTitles = sectionTitles;
    }

    return self;
}

+ (UIViewController *)instancesOfClassWithName:(NSString *)className retained:(BOOL)retain {
    NSArray<DSPObjectRef *> *references = [DSPHeapEnumerator
        instancesOfClassWithName:className retained:retain
    ];
    
    if (references.count == 1) {
        return [DSPObjectExplorerFactory
            explorerViewControllerForObject:references.firstObject.object
        ];
    }

    DSPObjectListViewController *controller = [[self alloc] initWithReferences:references];
    controller.title = [NSString stringWithFormat:@"%@ (%@)", className, @(references.count)];
    return controller;
}

+ (instancetype)subclassesOfClassWithName:(NSString *)className {
    NSArray<DSPObjectRef *> *references = [DSPRuntimeUtility subclassesOfClassWithName:className];
    DSPObjectListViewController *controller = [[self alloc] initWithReferences:references];
    controller.title = [NSString stringWithFormat:@"Subclasses of %@ (%@)",
        className, @(references.count)
    ];

    return controller;
}

+ (instancetype)objectsWithReferencesToObject:(id)object retained:(BOOL)retain {
    NSArray<DSPObjectRef *> *instances = [DSPHeapEnumerator
        objectsWithReferencesToObject:object retained:retain
    ];

    DSPObjectListViewController *viewController = [[self alloc]
        initWithReferences:instances
        predicates:self.defaultPredicates
        sectionTitles:self.defaultSectionTitles
    ];
    viewController.title = [NSString stringWithFormat:@"Referencing %@ %p",
        [DSPRuntimeUtility safeClassNameForObject:object], object
    ];
    return viewController;
}


#pragma mark - Overrides

- (void)viewDidLoad {
    [super viewDidLoad];

    self.showsSearchBar = YES;
}

- (NSArray<DSPMutableListSection *> *)makeSections {
    if (self.predicates.count) {
        return [self buildSections:self.sectionTitles predicates:self.predicates];
    } else {
        return @[[self makeSection:self.references title:nil]];
    }
}


#pragma mark - Private

- (NSArray *)buildSections:(NSArray<NSString *> *)titles predicates:(NSArray<NSPredicate *> *)predicates {
    NSParameterAssert(titles.count == predicates.count);
    NSParameterAssert(titles); NSParameterAssert(predicates);

    return [NSArray dsp_forEachUpTo:titles.count map:^id(NSUInteger i) {
        NSArray *rows = [self.references filteredArrayUsingPredicate:predicates[i]];
        return [self makeSection:rows title:titles[i]];
    }];
}

- (DSPMutableListSection *)makeSection:(NSArray *)rows title:(NSString *)title {
    DSPMutableListSection *section = [DSPMutableListSection list:rows
        cellConfiguration:^(DSPTableViewCell *cell, DSPObjectRef *ref, NSInteger row) {
            cell.textLabel.text = ref.reference;
            cell.detailTextLabel.text = ref.summary;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } filterMatcher:^BOOL(NSString *filterText, DSPObjectRef *ref) {
            if (ref.summary && [ref.summary localizedCaseInsensitiveContainsString:filterText]) {
                return YES;
            }

            return [ref.reference localizedCaseInsensitiveContainsString:filterText];
        }
    ];

    section.selectionHandler = ^(UIViewController *host, DSPObjectRef *ref) {
        [host.navigationController pushViewController:[
            DSPObjectExplorerFactory explorerViewControllerForObject:ref.object
        ] animated:YES];
    };

    section.customTitle = title;
    return section;
}

@end
