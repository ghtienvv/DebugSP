#import "DSPRuntimeSafety.h"

NSUInteger const kDSPKnownUnsafeClassCount = 19;
Class * _UnsafeClasses = NULL;
CFSetRef DSPKnownUnsafeClasses = nil;
CFSetRef DSPKnownUnsafeIvars = nil;

#define DSPClassPointerOrCFNull(name) \
    (NSClassFromString(name) ?: (__bridge id)kCFNull)

#define DSPIvarOrCFNull(cls, name) \
    (class_getInstanceVariable([cls class], name) ?: (void *)kCFNull)

__attribute__((constructor))
static void DSPRuntimeSafteyInit() {
    DSPKnownUnsafeClasses = CFSetCreate(
        kCFAllocatorDefault,
        (const void **)(uintptr_t)DSPKnownUnsafeClassList(),
        kDSPKnownUnsafeClassCount,
        nil
    );

    Ivar unsafeIvars[] = {
        DSPIvarOrCFNull(NSURL, "_urlString"),
        DSPIvarOrCFNull(NSURL, "_baseURL"),
    };
    DSPKnownUnsafeIvars = CFSetCreate(
        kCFAllocatorDefault,
        (const void **)unsafeIvars,
        sizeof(unsafeIvars),
        nil
    );
}

const Class * DSPKnownUnsafeClassList() {
    if (!_UnsafeClasses) {
        const Class ignored[] = {
            DSPClassPointerOrCFNull(@"__ARCLite__"),
            DSPClassPointerOrCFNull(@"__NSCFCalendar"),
            DSPClassPointerOrCFNull(@"__NSCFTimer"),
            DSPClassPointerOrCFNull(@"NSCFTimer"),
            DSPClassPointerOrCFNull(@"__NSGenericDeallocHandler"),
            DSPClassPointerOrCFNull(@"NSAutoreleasePool"),
            DSPClassPointerOrCFNull(@"NSPlaceholderNumber"),
            DSPClassPointerOrCFNull(@"NSPlaceholderString"),
            DSPClassPointerOrCFNull(@"NSPlaceholderValue"),
            DSPClassPointerOrCFNull(@"Object"),
            DSPClassPointerOrCFNull(@"VMUArchitecture"),
            DSPClassPointerOrCFNull(@"JSExport"),
            DSPClassPointerOrCFNull(@"__NSAtom"),
            DSPClassPointerOrCFNull(@"_NSZombie_"),
            DSPClassPointerOrCFNull(@"_CNZombie_"),
            DSPClassPointerOrCFNull(@"__NSMessage"),
            DSPClassPointerOrCFNull(@"__NSMessageBuilder"),
            DSPClassPointerOrCFNull(@"FigIrisAutoTrimmerMotionSampleExport"),
            // Temporary until we have our own type encoding parser;
            // setVectors: has an invalid type encoding and crashes NSMethodSignature
            DSPClassPointerOrCFNull(@"_UIPointVector"),
        };
        
        assert((sizeof(ignored) / sizeof(Class)) == kDSPKnownUnsafeClassCount);

        _UnsafeClasses = (Class *)malloc(sizeof(ignored));
        memcpy(_UnsafeClasses, ignored, sizeof(ignored));
    }

    return _UnsafeClasses;
}

NSSet * DSPKnownUnsafeClassNames() {
    static NSSet *set = nil;
    if (!set) {
        NSArray *ignored = @[
            @"__ARCLite__",
            @"__NSCFCalendar",
            @"__NSCFTimer",
            @"NSCFTimer",
            @"__NSGenericDeallocHandler",
            @"NSAutoreleasePool",
            @"NSPlaceholderNumber",
            @"NSPlaceholderString",
            @"NSPlaceholderValue",
            @"Object",
            @"VMUArchitecture",
            @"JSExport",
            @"__NSAtom",
            @"_NSZombie_",
            @"_CNZombie_",
            @"__NSMessage",
            @"__NSMessageBuilder",
            @"FigIrisAutoTrimmerMotionSampleExport",
            @"_UIPointVector",
        ];

        set = [NSSet setWithArray:ignored];
        assert(set.count == kDSPKnownUnsafeClassCount);
    }

    return set;
}
