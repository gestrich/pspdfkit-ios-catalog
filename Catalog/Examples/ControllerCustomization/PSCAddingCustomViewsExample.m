//
//  Copyright © 2015-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCAssetLoader.h"
#import "PSCExample.h"

/// Simple example that add custom views on a PSPDFPageView.
@interface PSCCustomViewPDFViewController : PSPDFViewController <PSPDFViewControllerDelegate>
@end

@interface PSAddingCustomViewsExample : PSCExample
@end
@implementation PSAddingCustomViewsExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Adding custom overlay views";
        self.category = PSCExampleCategoryControllerCustomization;
        self.priority = 40;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    PSPDFDocument *document = [PSCAssetLoader documentWithName:PSCAssetNameJKHF];

    PSPDFConfiguration *configuration = [PSPDFConfiguration configurationWithBuilder:^(PSPDFConfigurationBuilder *builder) {
        builder.maximumZoomScale = 20.f;
    }];

    PSCCustomViewPDFViewController *controller = [[PSCCustomViewPDFViewController alloc] initWithDocument:document configuration:configuration];
    return controller;
}

@end

// Custom view subclass. To make sure that the custom view stays aligned with the pdf content,
// the view should conform to `PSPDFAnnotationPresenting` to receive callbacks when it should update its frame.
@interface PSCCustomView : UIView <PSPDFAnnotationPresenting>

@property (nonatomic, weak) PSPDFPageView *pageView;
@property (nonatomic) CGRect pdfRect;

- (id)initWithPSPDFPageView:(PSPDFPageView *)pageView andPDFRect:(CGRect)pdfRect;

@end

@implementation PSCCustomViewPDFViewController

#pragma mark - Lifecycle

- (instancetype)initWithDocument:(PSPDFDocument *)document configuration:(nullable PSPDFConfiguration *)configuration {
    if ((self = [super initWithDocument:document configuration:configuration])) {
        // Register for the delegate.
        self.delegate = self;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

#pragma mark - PSPDFViewControllerDelegate

- (void)pdfViewController:(PSPDFViewController *)pdfController didConfigurePageView:(PSPDFPageView *)pageView forPageAtIndex:(NSInteger)pageIndex {
    // This is the size of the page in PDF coordinates.
    CGSize pageSize = pageView.pageInfo.size;
    CGFloat customViewSize = 30;

    // Add four custom views on the 4 corners of page 0.
    // PSPDFKit will re-use PSPDFPageView but will also clear all "foreign" added views - you don't have to remove it yourself.
    // `pdfViewController:didConfigurePageView:forPageAtIndex:` will be called once, while the pageView is processed for the new page, so it's the perfect time to add custom views.
    if (pageView.pageIndex == 0) {
        // Add the custom view at a specific location in the PDF. This rect is given in PDF coordinates.
        // To read more about coordinate systems, check out: https://pspdfkit.com/guides/ios/current/faq/coordinate-spaces/
        CGRect pdfRect = CGRectMake(pageSize.width - customViewSize, pageSize.height - customViewSize, customViewSize, customViewSize);

        // Add the custom view
        PSCCustomView *customView = [[PSCCustomView alloc] initWithPSPDFPageView:pageView andPDFRect:pdfRect];
        customView.backgroundColor = UIColor.redColor;
        // Overlay views should be added to the pageView's annotationContainer view (even though they are not annotations).
        [pageView.annotationContainerView addSubview:customView];
        [customView didChangePageBounds:pageView.bounds]; // layout initially

        // Add another custom view
        pdfRect = CGRectMake(0, 0, customViewSize, customViewSize);
        customView = [[PSCCustomView alloc] initWithPSPDFPageView:pageView andPDFRect:pdfRect];
        customView.backgroundColor = UIColor.blueColor;
        [pageView.annotationContainerView addSubview:customView];
        [customView didChangePageBounds:pageView.bounds];

        // Add another custom view
        pdfRect = CGRectMake(pageSize.width - customViewSize, 0, customViewSize, customViewSize);
        customView = [[PSCCustomView alloc] initWithPSPDFPageView:pageView andPDFRect:pdfRect];
        customView.backgroundColor = UIColor.greenColor;
        [pageView.annotationContainerView addSubview:customView];
        [customView didChangePageBounds:pageView.bounds];

        // Add another custom view
        pdfRect = CGRectMake(0, pageSize.height - customViewSize, customViewSize, customViewSize);
        customView = [[PSCCustomView alloc] initWithPSPDFPageView:pageView andPDFRect:pdfRect];
        customView.backgroundColor = UIColor.yellowColor;
        [pageView.annotationContainerView addSubview:customView];
        [customView didChangePageBounds:pageView.bounds];
    }
}

@end

@implementation PSCCustomView

- (id)initWithPSPDFPageView:(PSPDFPageView *)pageView andPDFRect:(CGRect)pdfRect {
    // Here, we convert the PDF coordinates to view coordinates.
    CGRect viewRect = [pageView convertRect:pdfRect fromCoordinateSpace:pageView.pdfCoordinateSpace];
    if ((self = [super initWithFrame:viewRect])) {
        self.pdfRect = pdfRect;
        self.pageView = pageView;
    }
    return self;
}

// Called initially and on rotation change
- (void)didChangePageBounds:(CGRect)bounds {
    PSPDFPageView *pageView = self.pageView;
    if (!pageView) { return; }
    // When the page bounds change, we need to do the PDF coordinate -> view coordinate conversion again.
    self.frame = [pageView convertRect:self.pdfRect fromCoordinateSpace:pageView.pdfCoordinateSpace];
}

@end
