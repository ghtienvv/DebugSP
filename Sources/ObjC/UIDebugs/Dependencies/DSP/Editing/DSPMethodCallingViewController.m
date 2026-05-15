#import "DSPMethodCallingViewController.h"
#import "DSPRuntimeUtility.h"
#import "DSPFieldEditorView.h"
#import "DSPObjectExplorerFactory.h"
#import "DSPObjectExplorerViewController.h"
#import "DSPArgumentInputView.h"
#import "DSPArgumentInputViewFactory.h"
#import "DSPUtility.h"

@interface DSPMethodCallingViewController ()
@property (nonatomic, readonly) DSPMethod *method;
@end

@implementation DSPMethodCallingViewController

+ (instancetype)target:(id)target method:(DSPMethod *)method {
    return [[self alloc] initWithTarget:target method:method];
}

- (id)initWithTarget:(id)target method:(DSPMethod *)method {
    NSParameterAssert(method.isInstanceMethod == !object_isClass(target));

    self = [super initWithTarget:target data:method commitHandler:nil];
    if (self) {
        self.title = method.isInstanceMethod ? @"Method: " : @"Class Method: ";
        self.title = [self.title stringByAppendingString:method.selectorString];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.actionButton.title = @"Call";

    // Configure field editor view
    self.fieldEditorView.argumentInputViews = [self argumentInputViews];
    self.fieldEditorView.fieldDescription = [NSString stringWithFormat:
        @"Signature:\n%@\n\nReturn Type:\n%s",
        self.method.description, (char *)self.method.returnType
    ];
}

- (NSArray<DSPArgumentInputView *> *)argumentInputViews {
    Method method = self.method.objc_method;
    NSArray *methodComponents = [DSPRuntimeUtility prettyArgumentComponentsForMethod:method];
    NSMutableArray<DSPArgumentInputView *> *argumentInputViews = [NSMutableArray new];
    unsigned int argumentIndex = kDSPNumberOfImplicitArgs;

    for (NSString *methodComponent in methodComponents) {
        char *argumentTypeEncoding = method_copyArgumentType(method, argumentIndex);
        DSPArgumentInputView *inputView = [DSPArgumentInputViewFactory argumentInputViewForTypeEncoding:argumentTypeEncoding];
        free(argumentTypeEncoding);

        inputView.backgroundColor = self.view.backgroundColor;
        inputView.title = methodComponent;
        [argumentInputViews addObject:inputView];
        argumentIndex++;
    }

    return argumentInputViews;
}

- (void)actionButtonPressed:(id)sender {
    // Gather arguments
    NSMutableArray *arguments = [NSMutableArray new];
    for (DSPArgumentInputView *inputView in self.fieldEditorView.argumentInputViews) {
        // Use NSNull as a nil placeholder; it will be interpreted as nil
        [arguments addObject:inputView.inputValue ?: NSNull.null];
    }

    // Call method
    NSError *error = nil;
    id returnValue = [DSPRuntimeUtility
        performSelector:self.method.selector
        onObject:self.target
        withArguments:arguments
        error:&error
    ];
    
    // Dismiss keyboard and handle committed changes
    [super actionButtonPressed:sender];

    // Display return value or error
    if (error) {
        [DSPAlert showAlert:@"Method Call Failed" message:error.localizedDescription from:self];
    } else if (returnValue) {
        // For non-nil (or void) return types, push an explorer view controller to display the returned object
        returnValue = [DSPRuntimeUtility potentiallyUnwrapBoxedPointer:returnValue type:self.method.returnType];
        DSPObjectExplorerViewController *explorer = [DSPObjectExplorerFactory explorerViewControllerForObject:returnValue];
        [self.navigationController pushViewController:explorer animated:YES];
    } else {
        [self exploreObjectOrPopViewController:returnValue];
    }
}

- (DSPMethod *)method {
    return _data;
}

@end
