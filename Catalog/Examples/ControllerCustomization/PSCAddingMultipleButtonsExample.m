//
//  Copyright © 2015-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCAssetLoader.h"
#import "PSCExample.h"

@interface PSCImageOverlayPDFViewController : PSPDFViewController <PSPDFViewControllerDelegate>
@end

@interface PSCAddingMultipleButtonsExample : PSCExample
@end
@implementation PSCAddingMultipleButtonsExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Adding multiple buttons";
        self.contentDescription = @"Will add a custom button above all PDF images.";
        self.category = PSCExampleCategoryControllerCustomization;
        self.priority = 50;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    PSPDFDocument *document = [PSCAssetLoader documentWithName:PSCAssetNameJKHF];
    return [[PSCImageOverlayPDFViewController alloc] initWithDocument:document];
}

@end

@interface PSCAutoResizeButton : UIButton <PSPDFAnnotationPresenting>

@property (nonatomic) CGRect targetPDFRect;
@property (nonatomic) PSPDFImageInfo *imageInfo;

@end

@implementation PSCImageOverlayPDFViewController

#pragma mark - PSPDFViewController

- (void)commonInitWithDocument:(PSPDFDocument *)document configuration:(PSPDFConfiguration *)configuration {
    [super commonInitWithDocument:document configuration:[configuration configurationUpdatedWithBuilder:^(PSPDFConfigurationBuilder *builder) {
        builder.pageTransition = PSPDFPageTransitionCurl;
    }]];
    self.delegate = self;
}

#pragma mark - PSPDFViewControllerDelegate

- (void)pdfViewController:(PSPDFViewController *)pdfController didConfigurePageView:(PSPDFPageView *)pageView forPageAtIndex:(NSInteger)pageIndex {
    // Iterate over all images and add button overlays on top.
    // Accessing the text parser will block the thread, so it'll be better to access the in a background thread and than use the result on the main thread (but then you'll have to check if the pageView still points at the same page which would add too much complexity for this simple example.)
    PSPDFDocument *document = pageView.presentationContext.document;
    for (PSPDFImageInfo *imageInfo in [document textParserForPageAtIndex:pageView.pageIndex].images) {
        // Create the view
        PSCAutoResizeButton *resizeButton = [PSCAutoResizeButton new];
        resizeButton.targetPDFRect = imageInfo.boundingBox;
        resizeButton.imageInfo = imageInfo;
        resizeButton.showsTouchWhenHighlighted = YES;
        resizeButton.layer.borderColor = UIColor.redColor.CGColor;
        resizeButton.layer.borderWidth = 2.0;
        resizeButton.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
        [resizeButton addTarget:self action:@selector(imageButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        // Add to container view. Only here views will get notified on changes via PSPDFAnnotationPresenting.
        // The container view will be purged when the page is prepared for reusage.
        [pageView.annotationContainerView addSubview:resizeButton];
    }
}

#pragma mark - Private

- (void)imageButtonPressed:(PSCAutoResizeButton *)button {
    NSParameterAssert([button isKindOfClass:PSCAutoResizeButton.class]);

    PSPDFImageInfo *imageInfo = button.imageInfo;
    UIImage *image = [imageInfo imageWithError:NULL];

    // Show view controller
    if (image) {
        UIViewController *imagePreviewController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
        imagePreviewController.title = @"Image";
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.backgroundColor = UIColor.blackColor;
        imagePreviewController.view = imageView;
        imagePreviewController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:imagePreviewController options:@{ PSPDFPresentationOptionInNavigationController: @YES, PSPDFPresentationOptionCloseButton: @YES } animated:YES sender:button completion:NULL];
    }
}

@end

@implementation PSCAutoResizeButton

// Will resize the view anytime the parent changes.
- (void)didChangePageBounds:(CGRect)bounds {
    PSPDFPageView *pageView = (PSPDFPageView *)self.superview.superview;
    self.frame = [pageView convertRect:self.targetPDFRect fromCoordinateSpace:pageView.pdfCoordinateSpace];
}

@end
