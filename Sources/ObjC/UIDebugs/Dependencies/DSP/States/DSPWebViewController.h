#import <UIKit/UIKit.h>

@interface DSPWebViewController : UIViewController

- (id)initWithURL:(NSURL *)url;
- (id)initWithText:(NSString *)text;

+ (BOOL)supportsPathExtension:(NSString *)extension;

@end
