#import <Foundation/Foundation.h>

@protocol DSPFileBrowserSearchOperationDelegate;

@interface DSPFileBrowserSearchOperation : NSOperation

@property (nonatomic, weak) id<DSPFileBrowserSearchOperationDelegate> delegate;

- (id)initWithPath:(NSString *)currentPath searchString:(NSString *)searchString;

@end

@protocol DSPFileBrowserSearchOperationDelegate <NSObject>

- (void)fileBrowserSearchOperationResult:(NSArray<NSString *> *)searchResult size:(uint64_t)size;

@end
