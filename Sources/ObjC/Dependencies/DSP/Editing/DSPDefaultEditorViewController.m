#import "DSPDefaultEditorViewController.h"
#import "DSPFieldEditorView.h"
#import "DSPRuntimeUtility.h"
#import "DSPArgumentInputView.h"
#import "DSPArgumentInputViewFactory.h"

@interface DSPDefaultEditorViewController ()

@property (nonatomic, readonly) NSUserDefaults *defaults;
@property (nonatomic, readonly) NSString *key;

@end

@implementation DSPDefaultEditorViewController

+ (instancetype)target:(NSUserDefaults *)defaults key:(NSString *)key commitHandler:(void(^_Nullable)(void))onCommit {
    DSPDefaultEditorViewController *editor = [self target:defaults data:key commitHandler:onCommit];
    editor.title = @"Edit Default";
    return editor;
}

- (NSUserDefaults *)defaults {
    return [_target isKindOfClass:[NSUserDefaults class]] ? _target : nil;
}

- (NSString *)key {
    return _data;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.fieldEditorView.fieldDescription = self.key;

    id currentValue = [self.defaults objectForKey:self.key];
    DSPArgumentInputView *inputView = [DSPArgumentInputViewFactory
        argumentInputViewForTypeEncoding:DSPEncodeObject(currentValue)
        currentValue:currentValue
    ];
    inputView.backgroundColor = self.view.backgroundColor;
    inputView.inputValue = currentValue;
    self.fieldEditorView.argumentInputViews = @[inputView];
}

- (void)actionButtonPressed:(id)sender {
    id value = self.firstInputView.inputValue;
    if (value) {
        [self.defaults setObject:value forKey:self.key];
    } else {
        [self.defaults removeObjectForKey:self.key];
    }
    [self.defaults synchronize];
    
    // Dismiss keyboard and handle committed changes
    [super actionButtonPressed:sender];
    
    // Go back after setting, but not for switches.
    if (sender) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        self.firstInputView.inputValue = [self.defaults objectForKey:self.key];
    }
}

+ (BOOL)canEditDefaultWithValue:(id)currentValue {
    return [DSPArgumentInputViewFactory
        canEditFieldWithTypeEncoding:DSPEncodeObject(currentValue)
        currentValue:currentValue
    ];
}

@end
