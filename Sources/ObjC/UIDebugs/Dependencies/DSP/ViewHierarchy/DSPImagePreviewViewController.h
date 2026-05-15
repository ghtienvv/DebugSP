#import <UIKit/UIKit.h>

@interface DSPImagePreviewViewController : UIViewController

+ (instancetype)previewForView:(UIView *)view;
+ (instancetype)previewForLayer:(CALayer *)layer;
+ (instancetype)forImage:(UIImage *)image;

@end
