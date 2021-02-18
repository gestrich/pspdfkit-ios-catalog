//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCExample.h"
#import "PSCMacros.h"

@interface NSObject (PSPDFSwiftDetector)

/// Helps to detect if class is a Swift object. Implemented in PSPDFKit.framework (SPI)
- (BOOL)pspdf_isSwift;

@end

@implementation PSCExample

#pragma mark - Lifecycle

- (instancetype)init {
    if ((self = [super init])) {
        _targetDevice = PSCExampleTargetDeviceMaskPhone | PSCExampleTargetDeviceMaskPad;
        _wantsModalPresentation = NO;
        _embedModalInNavigationController = YES;
        _prefersLargeTitles = YES;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    return nil;
}

- (BOOL)isSwift {
    return self.pspdf_isSwift;
}

@end

NSString *PSCHeaderFromExampleCategory(PSCExampleCategory category) {
    PSC_SWITCH_NOWARN(category) {
        case PSCExampleCategoryTop:
            return @"Basics";
        case PSCExampleCategorySwiftUI:
            return @"SwiftUI";
        case PSCExampleCategoryMultimedia:
            return @"Multimedia";
        case PSCExampleCategoryAnnotations:
            return @"Annotations";
        case PSCExampleCategoryAnnotationProviders:
            return @"Annotation Providers";
        case PSCExampleCategoryForms:
            return @"Forms and Digital Signatures";
        case PSCExampleCategoryBarButtons:
            return @"Toolbar Customizations";
        case PSCExampleCategoryViewCustomization:
            return @"View Customizations";
        case PSCExampleCategoryControllerCustomization:
            return @"PDFViewController Customization";
        case PSCExampleCategoryMiscellaneous:
            return @"Miscellaneous Examples";
        case PSCExampleCategoryTextExtraction:
            return @"Text Extraction / PDF Creation";
        case PSCExampleCategoryDocumentEditing:
            return @"Document Editing";
        case PSCExampleCategoryDocumentProcessing:
            return @"Document Processing";
        case PSCExampleCategoryDocumentGeneration:
            return @"Document Generation";
        case PSCExampleCategoryStoryboards:
            return @"Storyboards";
        case PSCExampleCategoryDocumentDataProvider:
            return @"Document Data Providers";
        case PSCExampleCategorySecurity:
            return @"Passwords / Security";
        case PSCExampleCategorySubclassing:
            return @"Subclassing";
        case PSCExampleCategorySharing:
            return @"Document Sharing";
        case PSCExampleCategoryComponentsExamples:
            return @"Components";
        case PSCExampleCategoryAnalyticsClient:
            return @"Analytics Client";
        case PSCExampleCategoryTests:
            return @"Miscelleaneous Test Cases";
        default:
            return @"";
    }
}

NSString *PSCFooterFromExampleCategory(PSCExampleCategory category) {
    PSC_SWITCH_NOWARN(category) {
        case PSCExampleCategoryTop:
            return @"Taking your first steps with PSPDFKit.";
        case PSCExampleCategorySwiftUI:
            return @"Examples illustrating how PSPDFKit can be used in SwiftUI projects.";
        case PSCExampleCategoryMultimedia:
            return @"Integrate videos, audio, images and HTML5 content/websites as part of a document page.";
        case PSCExampleCategoryAnnotations:
            return @"Add, edit or customize different annotations and annotation types.";
        case PSCExampleCategoryAnnotationProviders:
            return @"Examples with different annotation providers.";
        case PSCExampleCategoryForms:
            return @"Interact with or fill forms.";
        case PSCExampleCategoryBarButtons:
            return @"Customize the (annotation) toolbar.";
        case PSCExampleCategoryViewCustomization:
            return @"Various ways to customize the view.";
        case PSCExampleCategoryControllerCustomization:
            return @"Multiple ways to customize PDFViewController.";
        case PSCExampleCategoryMiscellaneous:
            return @"Examples showing how to customize PSPDFKit for various use cases.";
        case PSCExampleCategoryTextExtraction:
            return @"Extract text from document pages and create new document.";
        case PSCExampleCategoryDocumentEditing:
            return @"New page creation, page duplication, reordering, rotation, deletion and exporting.";
        case PSCExampleCategoryDocumentProcessing:
            return @"Various use cases for PSPDFProcessor, like annotation processing and page modifications.";
        case PSCExampleCategoryDocumentGeneration:
            return @"Generate PDF Documents.";
        case PSCExampleCategoryStoryboards:
            return @"Initialize a PDFViewController using storyboards.";
        case PSCExampleCategoryDocumentDataProvider:
            return @"Merge multiple file sources to one logical one using the highly flexible PSPDFDocument.";
        case PSCExampleCategorySecurity:
            return @"Enable encryption and open password protected documents.";
        case PSCExampleCategorySubclassing:
            return @"Various ways to subclass PSPDFKit.";
        case PSCExampleCategorySharing:
            return @"Examples showing how to customize the sharing experience.";
        case PSCExampleCategoryComponentsExamples:
            return @"Examples showing the various PSPDFKit components.";
        case PSCExampleCategoryAnalyticsClient:
            return @"Examples using PDFAnalyticsClient.";
        default:
            return @"";
    }
}
