#import "DSPActivityViewController.h"
#import "DSPMacros.h"

@interface DSPActivityViewController ()
@end

@implementation DSPActivityViewController

+ (id)sharing:(NSArray *)items source:(id)sender {
    UIViewController *shareSheet = [[UIActivityViewController alloc]
        initWithActivityItems:items applicationActivities:nil
    ];
    
    if (sender && UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIPopoverPresentationController *popover = shareSheet.popoverPresentationController;
        
        // Source view
        if ([sender isKindOfClass:UIView.self]) {
            popover.sourceView = sender;
        }
        // Source bar item
        if ([sender isKindOfClass:UIBarButtonItem.self]) {
            popover.barButtonItem = sender;
        }
        // Source rect
        if ([sender isKindOfClass:NSValue.self]) {
            CGRect rect = [sender CGRectValue];
            popover.sourceRect = rect;
        }
    }
    
    return shareSheet;
}

@end
