//
//  Copyright © 2015-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCAssetLoader.h"
#import "PSCExample.h"

@interface PSCBooksHighlightingViewController : PSPDFViewController
@end

@interface PSCBooksHighlightingExample : PSCExample
@end
@implementation PSCBooksHighlightingExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Highlighting like Apple Books";
        self.contentDescription = @"Selecting text automatically creates a highlight and shows the menu.";
        self.category = PSCExampleCategoryControllerCustomization;
        self.priority = 25;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    PSPDFDocument *document = [PSCAssetLoader documentWithName:PSCAssetNameJKHF];
    PSPDFViewController *pdfController = [[PSCBooksHighlightingViewController alloc] initWithDocument:document];
    return pdfController;
}

@end

@interface PSCBooksHighlightingViewController () <PSPDFViewControllerDelegate, UIGestureRecognizerDelegate> {
    BOOL _isFreshSelection;
    BOOL _isSelectingText;
}
@end

@implementation PSCBooksHighlightingViewController

#pragma mark - PSPDFViewController

- (void)commonInitWithDocument:(PSPDFDocument *)document configuration:(PSPDFConfiguration *)configuration {
    [super commonInitWithDocument:document configuration:[configuration configurationUpdatedWithBuilder:^(PSPDFConfigurationBuilder *builder) {
        // Disable the long press menu to block creating other types of annotations.
        builder.createAnnotationMenuEnabled = NO;
        builder.textSelectionMode = PSPDFTextSelectionModeSimple;
        builder.backgroundColor = UIColor.blackColor;
    }]];
    self.delegate = self;

    // Remove annotationButtonItem since we only want highlight annotations, and these are created without going into a special mode.
    // We use the annotationStateManager exclusively for highlights with Apple Pencil.
    [self.navigationItem setRightBarButtonItems:@[self.thumbnailsButtonItem, self.activityButtonItem, self.outlineButtonItem, self.searchButtonItem] forViewMode:PSPDFViewModeDocument animated:NO];

    // All touches with Apple Pencil should create highlight annotations.
    self.annotationStateManager.state = PSPDFAnnotationStringHighlight;
    self.annotationStateManager.stylusMode = PSPDFAnnotationStateManagerStylusModeStylus;

    UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerDidChangeState:)];
    [self.interactions.allInteractions allowSimultaneousRecognitionWithGestureRecognizer:gestureRecognizer];
    [self.view addGestureRecognizer:gestureRecognizer];
}

#pragma mark - PSPDFViewControllerDelegate

- (void)pdfViewController:(PSPDFViewController *)pdfController didSelectText:(NSString *)text withGlyphs:(NSArray *)glyphs atRect:(CGRect)rect onPageView:(PSPDFPageView *)pageView {
    // Track that we are changing the word selection.
    _isSelectingText = text.length > 0;
}

- (void)longPressGestureRecognizerDidChangeState:(UILongPressGestureRecognizer *)gestureRecognizer {
    // Check if there is a page view underneath the gesture.
    PSPDFPageView *pageView = [self.documentViewController visiblePageViewAtPoint:[gestureRecognizer locationInView:self.documentViewController.view]];
    if (!pageView) {
        return;
    }

    // Track that initially, nothing is selected.
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        _isFreshSelection = pageView.selectionView.selectedGlyphs.count == 0;
    }

    // If the gesture ended and we have a selection, create a highlight annotation.
    else if (_isSelectingText && _isFreshSelection && gestureRecognizer.state == UIGestureRecognizerStateEnded && pageView.selectionView.selectedGlyphs.count > 0) {
        // Create annotation and add to document.
        PSPDFDocument *document = self.document;
        PSPDFHighlightAnnotation *highlight = [PSPDFHighlightAnnotation textOverlayAnnotationWithGlyphs:pageView.selectionView.selectedGlyphs];
        highlight.pageIndex = pageView.pageIndex;
        [document addAnnotations:@[highlight] options:nil];

        // Update visible page and discard current selection.
        [pageView.selectionView discardSelectionAnimated:NO];
        [pageView addAnnotation:highlight options:nil animated:NO];

        // Wait until long press touch processing is complete, then select and show menu.
        dispatch_async(dispatch_get_main_queue(), ^{
            pageView.selectedAnnotations = @[highlight];
            [pageView showMenuIfSelectedAnimated:YES];
        });
    }
}

@end
