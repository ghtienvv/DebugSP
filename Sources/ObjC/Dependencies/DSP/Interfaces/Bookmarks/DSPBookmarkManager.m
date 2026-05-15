#import "DSPBookmarkManager.h"

static NSMutableArray *kDSPBookmarkManagerBookmarks = nil;

@implementation DSPBookmarkManager

+ (void)initialize {
    if (self == [DSPBookmarkManager class]) {
        kDSPBookmarkManagerBookmarks = [NSMutableArray new];
    }
}

+ (NSMutableArray *)bookmarks {
    return kDSPBookmarkManagerBookmarks;
}

@end
