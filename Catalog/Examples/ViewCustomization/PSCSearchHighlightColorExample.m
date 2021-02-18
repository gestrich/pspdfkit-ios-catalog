//
//  Copyright © 2014-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCAssetLoader.h"
#import "PSCExample.h"

@interface PSCCustomColoredSearchHighlightPDFViewController : PSPDFViewController
@end

@interface PSCSearchHighlightColorExample : PSCExample
@end
@implementation PSCSearchHighlightColorExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Custom Search Highlight Color";
        self.contentDescription = @"Changes the search highlight color to blue via UIAppearance.";
        self.category = PSCExampleCategoryViewCustomization;
        self.priority = 50;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    PSPDFDocument *document = [PSCAssetLoader documentWithName:PSCAssetNameQuickStart];

    // We use a custom subclass of the PSPDFViewController to avoid polluting other examples, since UIAppearance can't be reset to the default.
    [PSPDFSearchHighlightView appearanceWhenContainedInInstancesOfClasses:@[PSCCustomColoredSearchHighlightPDFViewController.class]].selectionBackgroundColor = [UIColor.blueColor colorWithAlphaComponent:0.5];

    PSPDFViewController *pdfController = [[PSCCustomColoredSearchHighlightPDFViewController alloc] initWithDocument:document configuration:[PSPDFConfiguration configurationWithBuilder:^(PSPDFConfigurationBuilder *builder) {
        builder.searchMode = PSPDFSearchModeInline;
    }]];

    // Automatically start search.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [pdfController searchForString:@"PSPDFKit" options:nil sender:nil animated:YES];
    });

    return pdfController;
}

@end

// Custom empty subclass of the PSPDFViewController to avoid polluting other examples, since UIAppearance can't be reset to the default.
@implementation PSCCustomColoredSearchHighlightPDFViewController
@end
