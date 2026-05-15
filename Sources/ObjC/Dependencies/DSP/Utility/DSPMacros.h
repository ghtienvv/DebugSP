#ifndef DSPMacros_h
#define DSPMacros_h

#ifndef __cplusplus
#ifndef auto
#define auto __auto_type
#endif
#endif

#define dsp_keywordify class NSObject;
#define ctor dsp_keywordify __attribute__((constructor)) void __dsp_ctor_##__LINE__()
#define dtor dsp_keywordify __attribute__((destructor)) void __dsp_dtor_##__LINE__()

#ifndef strongify

#define weakify(var) __weak __typeof(var) __weak__##var = var;

#define strongify(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = __weak__##var; \
_Pragma("clang diagnostic pop")

#endif

// A macro to check if we are running in a test environment
#define DSP_IS_TESTING() (NSClassFromString(@"XCTest") != nil)

/// Whether we want the majority of constructors to run upon load or not.
extern BOOL DSPConstructorsShouldRun(void);

/// A macro to return from the current procedure if we don't want to run constructors
#define DSP_EXIT_IF_NO_CTORS() if (!DSPConstructorsShouldRun()) return;

/// Rounds down to the nearest "point" coordinate
NS_INLINE CGFloat DSPFloor(CGFloat x) {
    return floor(UIScreen.mainScreen.scale * (x)) / UIScreen.mainScreen.scale;
}

/// Returns the given number of points in pixels
NS_INLINE CGFloat DSPPointsToPixels(CGFloat points) {
    return points / UIScreen.mainScreen.scale;
}

/// Creates a CGRect with all members rounded down to the nearest "point" coordinate
NS_INLINE CGRect DSPRectMake(CGFloat x, CGFloat y, CGFloat width, CGFloat height) {
    return CGRectMake(DSPFloor(x), DSPFloor(y), DSPFloor(width), DSPFloor(height));
}

/// Adjusts the origin of an existing rect
NS_INLINE CGRect DSPRectSetOrigin(CGRect r, CGPoint origin) {
    r.origin = origin; return r;
}

/// Adjusts the size of an existing rect
NS_INLINE CGRect DSPRectSetSize(CGRect r, CGSize size) {
    r.size = size; return r;
}

/// Adjusts the origin.x of an existing rect
NS_INLINE CGRect DSPRectSetX(CGRect r, CGFloat x) {
    r.origin.x = x; return r;
}

/// Adjusts the origin.y of an existing rect
NS_INLINE CGRect DSPRectSetY(CGRect r, CGFloat y) {
    r.origin.y = y ; return r;
}

/// Adjusts the size.width of an existing rect
NS_INLINE CGRect DSPRectSetWidth(CGRect r, CGFloat width) {
    r.size.width = width; return r;
}

/// Adjusts the size.height of an existing rect
NS_INLINE CGRect DSPRectSetHeight(CGRect r, CGFloat height) {
    r.size.height = height; return r;
}

#define DSPPluralString(count, plural, singular) [NSString \
    stringWithFormat:@"%@ %@", @(count), (count == 1 ? singular : plural) \
]

#define DSPPluralFormatString(count, pluralFormat, singularFormat) [NSString \
    stringWithFormat:(count == 1 ? singularFormat : pluralFormat), @(count)  \
]

#define dsp_dispatch_after(nSeconds, onQueue, block) \
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, \
    (int64_t)(nSeconds * NSEC_PER_SEC)), onQueue, block)

#endif /* DSPMacros_h */
