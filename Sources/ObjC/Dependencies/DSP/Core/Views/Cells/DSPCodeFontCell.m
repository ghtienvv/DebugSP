#import "DSPCodeFontCell.h"
#import "UIFont+DSP.h"

@implementation DSPCodeFontCell

- (void)postInit {
    [super postInit];
    
    self.titleLabel.font = UIFont.dsp_codeFont;
    self.subtitleLabel.font = UIFont.dsp_codeFont;

    self.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.titleLabel.minimumScaleFactor = 0.9;
    self.subtitleLabel.adjustsFontSizeToFitWidth = YES;
    self.subtitleLabel.minimumScaleFactor = 0.75;
    
    // Disable mutli-line pre iOS 11
    if (@available(iOS 11, *)) {
        self.subtitleLabel.numberOfLines = 5;
    } else {
        self.titleLabel.numberOfLines = 1;
        self.subtitleLabel.numberOfLines = 1;
    }
}

@end
