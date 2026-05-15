#import "DSPLayerShortcuts.h"
#import "DSPShortcut.h"
#import "DSPImagePreviewViewController.h"

@implementation DSPLayerShortcuts

+ (instancetype)forObject:(CALayer *)layer {
    return [self forObject:layer additionalRows:@[
        [DSPActionShortcut title:@"Preview Image" subtitle:nil
            viewer:^UIViewController *(CALayer *layer) {
                return [DSPImagePreviewViewController previewForLayer:layer];
            }
            accessoryType:^UITableViewCellAccessoryType(CALayer *layer) {
                return CGRectIsEmpty(layer.bounds) ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
            }
        ]
    ]];
}

@end
