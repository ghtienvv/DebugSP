#import "DSPFieldEditorViewController.h"
#import "DSPFieldEditorView.h"
#import "DSPArgumentInputViewFactory.h"
#import "DSPPropertyAttributes.h"
#import "DSPRuntimeUtility.h"
#import "DSPMetadataExtras.h"
#import "DSPUtility.h"
#import "DSPColor.h"
#import "UIBarButtonItem+DSP.h"

@interface DSPFieldEditorViewController () <DSPArgumentInputViewDelegate>

@property (nonatomic, readonly) id<DSPMetadataAuxiliaryInfo> auxiliaryInfoProvider;
@property (nonatomic) DSPProperty *property;
@property (nonatomic) DSPIvar *ivar;

@property (nonatomic, readonly) id currentValue;
@property (nonatomic, readonly) const DSPTypeEncoding *typeEncoding;
@property (nonatomic, readonly) NSString *fieldDescription;

@end

@implementation DSPFieldEditorViewController

#pragma mark - Initialization

+ (instancetype)target:(id)target property:(nonnull DSPProperty *)property commitHandler:(void(^)(void))onCommit {
    DSPFieldEditorViewController *editor = [self target:target data:property commitHandler:onCommit];
    editor.title = [@"Property: " stringByAppendingString:property.name];
    editor.property = property;
    return editor;
}

+ (instancetype)target:(id)target ivar:(nonnull DSPIvar *)ivar commitHandler:(void(^)(void))onCommit {
    DSPFieldEditorViewController *editor = [self target:target data:ivar commitHandler:onCommit];
    editor.title = [@"Ivar: " stringByAppendingString:ivar.name];
    editor.ivar = ivar;
    return editor;
}

#pragma mark - Overrides

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = DSPColor.groupedBackgroundColor;

    // Create getter button
    _getterButton = [[UIBarButtonItem alloc]
        initWithTitle:@"Get"
        style:UIBarButtonItemStyleDone
        target:self
        action:@selector(getterButtonPressed:)
    ];
    self.toolbarItems = @[
        UIBarButtonItem.dsp_dspibleSpace, self.getterButton, self.actionButton
    ];
    
    [self registerAuxiliaryInfo];

    // Configure input view
    self.fieldEditorView.fieldDescription = self.fieldDescription;
    DSPArgumentInputView *inputView = [DSPArgumentInputViewFactory argumentInputViewForTypeEncoding:self.typeEncoding];
    inputView.inputValue = self.currentValue;
    inputView.delegate = self;
    self.fieldEditorView.argumentInputViews = @[inputView];

    // Don't show a "set" button for switches; we mutate when the switch is flipped
    if ([inputView isKindOfClass:[DSPArgumentInputSwitchView class]]) {
        self.actionButton.enabled = NO;
        self.actionButton.title = @"Flip the switch to call the setter";
        // Put getter button before setter button 
        self.toolbarItems = @[
            UIBarButtonItem.dsp_dspibleSpace, self.actionButton, self.getterButton
        ];
    }
}

- (void)actionButtonPressed:(id)sender {
    if (self.property) {
        id userInputObject = self.firstInputView.inputValue;
        NSArray *arguments = userInputObject ? @[userInputObject] : nil;
        SEL setterSelector = self.property.likelySetter;
        NSError *error = nil;
        [DSPRuntimeUtility performSelector:setterSelector onObject:self.target withArguments:arguments error:&error];
        if (error) {
            [DSPAlert showAlert:@"Property Setter Failed" message:error.localizedDescription from:self];
            sender = nil; // Don't pop back
        }
    } else {
        // TODO: check mutability and use mutableCopy if necessary;
        // this currently could and would assign NSArray to NSMutableArray
        [self.ivar setValue:self.firstInputView.inputValue onObject:self.target];
    }
    
    // Dismiss keyboard and handle committed changes
    [super actionButtonPressed:sender];

    // Go back after setting, but not for switches.
    if (sender) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        self.firstInputView.inputValue = self.currentValue;
    }
}

- (void)getterButtonPressed:(id)sender {
    [self.fieldEditorView endEditing:YES];

    [self exploreObjectOrPopViewController:self.currentValue];
}

- (void)argumentInputViewValueDidChange:(DSPArgumentInputView *)argumentInputView {
    if ([argumentInputView isKindOfClass:[DSPArgumentInputSwitchView class]]) {
        [self actionButtonPressed:nil];
    }
}

#pragma mark - Private

- (void)registerAuxiliaryInfo {
    // This is how the Swift mirror provides Swift struct field names to the editor at runtime.
    NSDictionary<NSString *, NSArray *> *labels = [self.auxiliaryInfoProvider
        auxiliaryInfoForKey:DSPAuxiliaryInfoKeyFieldLabels
    ];
    if (!labels.count) {
        labels = [self.auxiliaryInfoProvider
            auxiliaryInfoForKey:DSPAuxiliarynfoKeyFieldLabels
        ];
    }
    
    for (NSString *type in labels) {
        [DSPArgumentInputViewFactory registerFieldNames:labels[type] forTypeEncoding:type];
    }
}

- (id)currentValue {
    if (self.property) {
        return [self.property getValue:self.target];
    } else {
        return [self.ivar getValue:self.target];
    }
}

- (id<DSPMetadataAuxiliaryInfo>)auxiliaryInfoProvider {
    return self.ivar ?: self.property;
}

- (const DSPTypeEncoding *)typeEncoding {
    if (self.property) {
        return self.property.attributes.typeEncoding.UTF8String;
    } else {
        return self.ivar.typeEncoding.UTF8String;
    }
}

- (NSString *)fieldDescription {
    if (self.property) {
        return self.property.fullDescription;
    } else {
        return self.ivar.description;
    }
}

@end
