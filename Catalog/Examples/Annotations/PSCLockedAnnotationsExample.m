//
//  Copyright © 2015-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'LockedAnnotationsExample.swift' for the Swift version of this example.

#import "PSCAssetLoader.h"
#import "PSCExample.h"
#import "PSCFileHelper.h"
#import "PSPDFInkAnnotation+PSCSamples.h"
#import <tgmath.h>

@interface PSCLockedAnnotationsPDFViewController : PSPDFViewController
@end

@interface PSCLockedAnnotationsPageView : PSPDFPageView
@end

@interface PSCLockedAnnotationsExample : PSCExample
@end
@implementation PSCLockedAnnotationsExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Lock specific annotations";
        self.contentDescription = @"Example how to lock specific annotations. All black annotations cannot be moved anymore.";
        self.category = PSCExampleCategoryViewCustomization;
        self.priority = 110;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    PSPDFDocument *document = [PSCAssetLoader documentWithName:PSCAssetNameQuickStart];
    document.annotationSaveMode = PSPDFAnnotationSaveModeDisabled;

    // Add some test annotations.
    PSPDFInkAnnotation *ink = [PSPDFInkAnnotation psc_sampleInkAnnotationInRect:CGRectMake(100, 100, 200, 200)];
    ink.color = UIColor.greenColor;
    PSPDFInkAnnotation *ink2 = [PSPDFInkAnnotation psc_sampleInkAnnotationInRect:CGRectMake(300.0, 300.0, 200.0, 200.0)];
    ink2.color = UIColor.blackColor;
    PSPDFInkAnnotation *ink3 = [PSPDFInkAnnotation psc_sampleInkAnnotationInRect:CGRectMake(100.0, 400.0, 200.0, 200.0)];
    ink3.color = UIColor.redColor;
    [document addAnnotations:@[ink, ink2, ink3] options:nil];

    PSPDFViewController *pdfController = [[PSCLockedAnnotationsPDFViewController alloc] initWithDocument:document configuration:[PSPDFConfiguration configurationWithBuilder:^(PSPDFConfigurationBuilder *builder) {
        [builder overrideClass:PSPDFPageView.class withClass:PSCLockedAnnotationsPageView.class];
    }]];
    return pdfController;
}

@end

@implementation PSCLockedAnnotationsPDFViewController

- (void)commonInitWithDocument:(nullable PSPDFDocument *)document configuration:(PSPDFConfiguration *_Nonnull)configuration {
    [super commonInitWithDocument:document configuration:configuration];

    // Dynamically change selection mode if an annotation changes.
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(annotationsChangedNotification:) name:PSPDFAnnotationChangedNotification object:nil];
}

- (void)annotationsChangedNotification:(NSNotification *)notification {
    // Reevaluate all page views. Usually there's just one but this is more future-proof.
    for (PSPDFPageView *pageView in self.visiblePageViews) {
        [pageView updateAnnotationSelectionView];
    }
}

@end

@implementation PSCLockedAnnotationsPageView

- (void)didSelectAnnotations:(NSArray<PSPDFAnnotation *> *)annotations{
    [super didSelectAnnotations:annotations];

    [self updateAnnotationSelectionView];
}

- (void)updateAnnotationSelectionView {
    BOOL allowEditing = YES;
    for (PSPDFAnnotation *annotation in self.selectedAnnotations) {
        // Comparing colors is always tricky - we use a helper and allow some leeway.
        // The helper also deals with details like different color spaces.
        if (PSCIsColorAboutEqualToColorWithTolerance(annotation.color, UIColor.blackColor, 0.1)) {
            allowEditing = NO;
            break;
        }
    }
    self.annotationSelectionView.allowEditing = allowEditing;
}

#pragma mark - Helper

static UIColor *PSCColorInRGBColorSpace(UIColor *color) {
    UIColor *newColor = color;

    // convert UIDeviceWhiteColorSpace to UIDeviceRGBColorSpace.
    if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) != kCGColorSpaceModelRGB) {
        const CGFloat *components = CGColorGetComponents(color.CGColor);
        CGFloat whiteComponent = components[0];
        newColor = [UIColor colorWithRed:whiteComponent green:whiteComponent blue:whiteComponent alpha:components[1]];
    }

    return newColor;
}

static BOOL PSCIsColorAboutEqualToColorWithTolerance(UIColor *left, UIColor *right, CGFloat tolerance) {
    if (!left || !right) return NO;

    CGColorRef leftColor = PSCColorInRGBColorSpace(left).CGColor;
    CGColorRef rightColor = PSCColorInRGBColorSpace(right).CGColor;

    if (CGColorSpaceGetModel(CGColorGetColorSpace(leftColor)) != CGColorSpaceGetModel(CGColorGetColorSpace(rightColor))) {
        return NO;
    }

    NSInteger componentCount = CGColorGetNumberOfComponents(leftColor);
    const CGFloat *leftComponents = CGColorGetComponents(leftColor);
    const CGFloat *rightComponents = CGColorGetComponents(rightColor);

    for (NSInteger i = 0; i < componentCount; i++) {
        if (fabs(leftComponents[i] - rightComponents[i]) > tolerance) {
            return NO;
        }
    }

    return YES;
}

@end
