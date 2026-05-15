#import "DSPImageShortcuts.h"
#import "DSPImagePreviewViewController.h"
#import "DSPShortcut.h"
#import "DSPAlert.h"
#import "DSPMacros.h"

@interface UIAlertController (DSPImageShortcuts)
- (void)dsp_image:(UIImage *)image disSaveWithError:(NSError *)error :(void *)context;
@end

@implementation DSPImageShortcuts

#pragma mark - Overrides

+ (instancetype)forObject:(UIImage *)image {
    // These additional rows will appear at the beginning of the shortcuts section.
    // The methods below are written in such a way that they will not interfere
    // with properties/etc being registered alongside these
    return [self forObject:image additionalRows:@[
        [DSPActionShortcut title:@"View Image" subtitle:nil
            viewer:^UIViewController *(id image) {
                return [DSPImagePreviewViewController forImage:image];
            }
            accessoryType:^UITableViewCellAccessoryType(id image) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ],
        [DSPActionShortcut title:@"Save Image" subtitle:nil
            selectionHandler:^(UIViewController *host, id image) {
                // Present modal alerting user about saving
                UIAlertController *alert = [DSPAlert makeAlert:^(DSPAlert *make) {
                    make.title(@"Saving Image…");
                }];
                [host presentViewController:alert animated:YES completion:nil];
            
                // Save the image
                UIImageWriteToSavedPhotosAlbum(
                    image, alert, @selector(dsp_image:disSaveWithError::), nil
                );
            }
            accessoryType:^UITableViewCellAccessoryType(id image) {
                return UITableViewCellAccessoryDisclosureIndicator;
            }
        ]
    ]];
}

@end


@implementation UIAlertController (DSPImageShortcuts)

- (void)dsp_image:(UIImage *)image disSaveWithError:(NSError *)error :(void *)context {
    self.title = @"Image Saved";
    dsp_dispatch_after(1, dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

@end
