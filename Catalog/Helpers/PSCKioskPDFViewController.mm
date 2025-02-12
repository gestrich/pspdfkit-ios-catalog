//
//  Copyright © 2011-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCKioskPDFViewController.h"

#import "UINavigationItem+PSCFiltering.h"

@implementation PSCKioskPDFViewController

#pragma mark - Lifecycle

- (instancetype)initWithDocument:(PSPDFDocument *)document configuration:(PSPDFConfiguration *)configuration {
    if ((self = [super initWithDocument:document configuration:configuration])) {
        self.navigationItem.leftItemsSupplementBackButton = YES;

        self.delegate = self;

        __weak typeof(self) weakSelf = self;
        [self setUpdateSettingsForBoundsChangeBlock:^(PSPDFViewController *pdfController) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf updateBarButtonItems];
        }];
    }
    return self;
}

- (void)close:(id)sender {
    // Support the case where we pop in the nav stack
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        // We might have opened a linked document modally.
        [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
    }
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self updateBarButtonItems];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if (@available(iOS 13.0, *)) {
        self.view.window.windowScene.screenshotService.delegate = self;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (@available(iOS 13.0, *)) {
        if (self.view.window.windowScene.screenshotService.delegate == self) {
            self.view.window.windowScene.screenshotService.delegate = nil;
        }
    }
}

#pragma mark - PSPDFViewController

- (void)updateBarButtonItems {
    // We need update right bar button items first, because we're
    // moving some buttons that are on the right side by default to
    // the left side. They need to be removed first before being
    // added to the other side.
    [self updateRightBarButtonItems];
    [self updateLeftBarButtonItems];
}

- (void)updateLeftBarButtonItems {
    NSMutableArray *leftToolbarItems = [NSMutableArray array];

    [leftToolbarItems addObject:self.settingsButtonItem];

    const BOOL isWideHorizontally = (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad && self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) ||
                                    (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact);
    if (isWideHorizontally) {
        [leftToolbarItems addObject:self.outlineButtonItem];
    }

    [self.navigationItem setLeftBarButtonItems:leftToolbarItems forViewMode:PSPDFViewModeDocument animated:NO];
}

- (void)updateRightBarButtonItems {
    NSMutableArray<UIBarButtonItem *> *rightBarButtonItems = [NSMutableArray array];
    [rightBarButtonItems addObject:self.thumbnailsButtonItem];
    [rightBarButtonItems addObject:self.activityButtonItem];
    [rightBarButtonItems addObject:self.annotationButtonItem];
    [rightBarButtonItems addObject:self.searchButtonItem];

    // Make sure we don't overflow the available navigation bar space.
    NSArray<UIBarButtonItem *> *filteredItems = [UINavigationItem psc_filteredItems:rightBarButtonItems forNavigationBar:self.navigationController.navigationBar];
    [self.navigationItem setRightBarButtonItems:filteredItems forViewMode:PSPDFViewModeDocument animated:NO];
}

#pragma mark - PSPDFViewControllerDelegate

- (void)pdfViewControllerWillDismiss:(PSPDFViewController *)pdfController {
     PSCLog(@"Controller is about to be dismissed.");
}

- (void)pdfViewControllerDidDismiss:(PSPDFViewController *)pdfController {
     PSCLog(@"Controller has been dismissed.");
}

static NSString *PSCStripPDFFileType(NSString *pdfFileName) { return [pdfFileName stringByReplacingOccurrencesOfString:@".pdf" withString:@"" options:NSCaseInsensitiveSearch | NSBackwardsSearch range:NSMakeRange(0, pdfFileName.length)]; }

// Time to adjust PSPDFViewController before a PSPDFDocument is displayed.
- (void)pdfViewController:(PSPDFViewController *)pdfController didChangeDocument:(PSPDFDocument *)document {
    // show pdf title and fileURL
    if (document) {
        NSString *fileName = PSCStripPDFFileType(document.fileURL.lastPathComponent);
        if (PSCIsIPad() && ![document.title isEqualToString:fileName]) {
            self.title = [NSString stringWithFormat:@"%@ (%@)", document.title, document.fileURL.lastPathComponent];
        }
    }
}

// Helper to get the correct subclass out of various containers.
static id PSCControllerForClass(id theController, Class klass) {
#ifndef __clang_analyzer__
    if ([theController isKindOfClass:klass]) {
        return theController;
    } else if ([theController isKindOfClass:UINavigationController.class]) {
        return PSCControllerForClass(((UINavigationController *)theController).topViewController, klass);
    } else if ([theController isKindOfClass:PSPDFContainerViewController.class]) {
        for (UIViewController *contained in ((PSPDFContainerViewController *)theController).viewControllers) {
            if (PSCControllerForClass(contained, klass)) return PSCControllerForClass(contained, klass);
        }
    }
#endif
    return nil;
}

- (BOOL)pdfViewController:(PSPDFViewController *)pdfController shouldShowController:(UIViewController *)controller options:(nullable NSDictionary<NSString *, id> *)options animated:(BOOL)animated {
    PSCLog(@"shouldShowViewController: %@ animated: %d.", controller, animated);

    // Example how to customize PSPDFAnnotationTableViewController.
#ifndef __clang_analyzer__
    PSPDFAnnotationTableViewController *annotCtrl = PSCControllerForClass(controller, PSPDFAnnotationTableViewController.class);
    annotCtrl.showDeleteAllOption = YES;
#endif
    return YES;
}

- (void)pdfViewController:(PSPDFViewController *)pdfController didShowController:(UIViewController *)controller options:(nullable NSDictionary<NSString *, id> *)options animated:(BOOL)animated {
    PSCLog(@"didShowViewController: %@ animated: %d.", controller, animated);
}

- (BOOL)pdfViewController:(PSPDFViewController *)pdfController shouldSelectText:(NSString *)text withGlyphs:(NSArray *)glyphs atRect:(CGRect)rect onPageView:(PSPDFPageView *)pageView {
    // Example how to limit text selection.
    // return [text length] > 10;
    return YES;
}

- (NSArray<PSPDFMenuItem *> *)pdfViewController:(PSPDFViewController *)pdfController shouldShowMenuItems:(NSArray<PSPDFMenuItem *> *)menuItems atSuggestedTargetRect:(CGRect)rect forSelectedText:(NSString *)selectedText inRect:(CGRect)textRect onPageView:(PSPDFPageView *)pageView {
    // This is an example how to customize the text selection menu.
    // It helps for debugging text extraction issues. Don't ship this feature.
    NSMutableArray *newMenuItems = [menuItems mutableCopy];
    if (PSCIsIPad()) { // looks bad on iPhone, no space
        PSPDFMenuItem *menuItem = [[PSPDFMenuItem alloc] initWithTitle:PSPDFLocalize(@"Show Text") block:^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Custom Show Text Feature" message:selectedText preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:NULL]];
            [pdfController presentViewController:alert animated:YES completion:NULL];
        } identifier:@"Show Text"];
        [newMenuItems addObject:menuItem];
    }
    return newMenuItems;
}

// Annotations

/// Called before an annotation will be selected (but after didTapOnAnnotation).
- (NSArray *)pdfViewController:(PSPDFViewController *)pdfController shouldSelectAnnotations:(NSArray<PSPDFAnnotation *> *)annotations onPageView:(PSPDFPageView *)pageView {
    //    PSCLog(@"should select %@?", annotations);
    return annotations;
}

/// Called after an annotation has been selected.
- (void)pdfViewController:(PSPDFViewController *)pdfController didSelectAnnotations:(NSArray<PSPDFAnnotation *> *)annotations onPageView:(PSPDFPageView *)pageView {
    PSCLog(@"did select %@.", annotations);
}

/// Called before we're showing the menu for an annotation.
- (NSArray<PSPDFMenuItem *> *)pdfViewController:(PSPDFViewController *)pdfController shouldShowMenuItems:(NSArray<PSPDFMenuItem *> *)menuItems atSuggestedTargetRect:(CGRect)rect forAnnotations:(NSArray<PSPDFAnnotation *> *)annotations inRect:(CGRect)textRect onPageView:(PSPDFPageView *)pageView {
    // PSCLog(@"showing menu %@ for %@", menuItems, annotation);

    // Print highlight contents
    for (PSPDFAnnotation *annotation in annotations) {
        if ([annotation isKindOfClass:PSPDFHighlightAnnotation.class]) {
            NSString *highlightedString = ((PSPDFHighlightAnnotation *)annotation).markedUpString;
            PSCLog(@"Highlighted value: %@", highlightedString);
        }
    }

    // Example how to rename menu items.
    // for (PSPDFMenuItem *menuItem in menuItems) {
    //    menuItem.title = @"Test";
    //}

    return menuItems;
}

// Text Selection

- (void)pdfViewController:(PSPDFViewController *)pdfController didSelectText:(NSString *)text withGlyphs:(NSArray *)glyphs atRect:(CGRect)rect onPageView:(PSPDFPageView *)pageView {
     PSCLog(@"Selected text: %@", text);
}

@end
