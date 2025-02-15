//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCAssetLoader.h"
#import "PSCExample.h"

@interface PSCManualToolbarSetupExample : PSCExample
@end

@interface PSCManualToolbarSetupViewController : UIViewController <UIToolbarDelegate, PSPDFFlexibleToolbarContainerDelegate>
@property (nonatomic) PSPDFDocument *document;
@property (nonatomic) PSPDFViewController *pdfController;
@property (nonatomic) UIToolbar *toolbar;
@property (nonatomic) PSPDFFlexibleToolbarContainer *flexibleToolbarContainer;
- (instancetype)initWithDocument:(PSPDFDocument *)document; // Convenience
@end

@implementation PSCManualToolbarSetupExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Manual annotation toolbar setup and management";
        self.contentDescription = @"Flexible toolbar handling without UINavigationController or PSPDFAnnotationBarButtonItem.";
        self.category = PSCExampleCategoryBarButtons;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    PSPDFDocument *document = [PSCAssetLoader documentWithName:PSCAssetNameAnnualReport];
    PSCManualToolbarSetupViewController *controller = [[PSCManualToolbarSetupViewController alloc] initWithDocument:document];
    // Present modally, so we can more easily configure it to have a different style.
    [delegate.currentViewController presentViewController:controller animated:YES completion:NULL];
    return (UIViewController *)nil;
}

@end

@implementation PSCManualToolbarSetupViewController

#pragma mark - Lifecycle

- (instancetype)initWithDocument:(PSPDFDocument *)document {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _document = document;
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.psc_systemBackgroundColor;
    [self createPDFViewController];
}

- (void)createPDFViewController {
    // Add PSPDFViewController as a sub-controller
    self.pdfController = [[PSPDFViewController alloc] initWithDocument:self.document configuration:[PSPDFConfiguration configurationWithBuilder:^(PSPDFConfigurationBuilder *builder) {
        builder.userInterfaceViewMode = PSPDFUserInterfaceViewModeNever;
        builder.backgroundColor = UIColor.psc_systemBackgroundColor;
    }]];

    // Those need to be nilled out if you use the barButton items (e.g., annotationButtonItem) externally!
    self.pdfController.navigationItem.leftBarButtonItems = nil;
    self.pdfController.navigationItem.rightBarButtonItems = nil;

    [self addChildViewController:self.pdfController];
    [self.pdfController didMoveToParentViewController:self];
    [self.view addSubview:self.pdfController.view];

    // As an example, here we're not using the UINavigationController but instead a custom UIToolbar.
    // Note that if you're going that way, you'll lose some features that PSPDFKit provides, like dynamic toolbar updating or accessibility.
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    [toolbar sizeToFit];
    toolbar.frame = CGRectMake(0.0, 20.0, CGRectGetWidth(self.view.bounds), toolbar.frame.size.height);
    toolbar.delegate = self;
    toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    // Configure the toolbar items
    NSMutableArray *toolbarItems = [NSMutableArray array];
    toolbar.translucent = NO;
    [toolbarItems addObjectsFromArray:@[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)], [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]]];

    // Normally we would just use the annotationButtonItem and let it do all the toolbar setup and management for us.
    // Here, however we'll show how one could manually configure and show the annotation toolbar without using
    // PSPDFAnnotationBarButtonItem. Note that PSPDFAnnotationBarButtonItem handles quite a fiew more
    // cases and should in general be prefered to this simple toolbar setup.

    // It's still a good idea to check if annotations are avaialble
    if (self.pdfController.document.canSaveAnnotations) {
        [toolbarItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(toggleToolbar:)]];
    }

    toolbar.items = toolbarItems;
    [self.view addSubview:toolbar];
    self.toolbar = toolbar;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

    // Manually unload view.
    if (self.isViewLoaded && !self.view.window) {
        [self.pdfController willMoveToParentViewController:nil];
        [self.pdfController.view removeFromSuperview];
        [self.pdfController removeFromParentViewController];
        self.pdfController = nil;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

#pragma mark - Annotation toolbar

- (void)toggleToolbar:(id)sender {
    if (self.flexibleToolbarContainer) {
        [self.flexibleToolbarContainer hideAndRemoveAnimated:YES completion:NULL];
        return;
    }

    PSPDFAnnotationStateManager *manager = self.pdfController.annotationStateManager;
    PSPDFAnnotationToolbar *toolbar = [[PSPDFAnnotationToolbar alloc] initWithAnnotationStateManager:manager];
    [toolbar matchUIBarAppearance:self.toolbar]; // (optional)

    PSPDFFlexibleToolbarContainer *container = [[PSPDFFlexibleToolbarContainer alloc] initWithFrame:self.view.bounds];
    container.flexibleToolbar = toolbar;
    container.overlaidBar = self.toolbar;
    container.containerDelegate = self;
    [self.view addSubview:container];
    self.flexibleToolbarContainer = container;

    [container showAnimated:YES completion:NULL];
}

#pragma mark - PSPDFFlexibleToolbarContainerDelegate

- (void)flexibleToolbarContainerDidHide:(PSPDFFlexibleToolbarContainer *)container {
    self.flexibleToolbarContainer = nil;
}

- (CGRect)flexibleToolbarContainerContentRect:(PSPDFFlexibleToolbarContainer *)container {
    return self.pdfController.view.frame;
}

#pragma mark - Layout

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    // Position the pdfController content below the toolbar
    CGRect frame = self.view.bounds;
    frame.origin.y = CGRectGetMaxY(self.toolbar.frame);
    frame.size.height -= frame.origin.y;
    self.pdfController.view.frame = frame;
}

#pragma mark - Public

- (void)setDocument:(PSPDFDocument *)document {
    if (document != _document) {
        _document = document;
        self.pdfController.document = document;
    }
}

#pragma mark - Private

- (void)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UIBarPositioningDelegate

- (UIBarPosition)positionForBar:(id<UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

@end
