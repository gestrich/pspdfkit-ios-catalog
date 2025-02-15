//
//  Copyright © 2014-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCAssetLoader.h"
#import "PSCExample.h"

@interface PSCSimpleAnnotationStyleViewController : PSPDFAnnotationStyleViewController
@end

@interface PSCSimpleAnnotationInspectorExample : PSCExample <PSPDFViewControllerDelegate>
@end
@implementation PSCSimpleAnnotationInspectorExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Simple Annotation Inspector";
        self.contentDescription = @"Shows how to customize the annotation inspector to hide certain properties, making it simpler.";
        self.category = PSCExampleCategoryViewCustomization;
        self.priority = 30;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    PSPDFDocument *document = [PSCAssetLoader writableDocumentWithName:PSCAssetNameQuickStart overrideIfExists:NO];
    PSPDFViewController *pdfController = [[PSPDFViewController alloc] initWithDocument:document configuration:[PSPDFConfiguration configurationWithBuilder:^(PSPDFConfigurationBuilder *builder) {
        // Overrides the inspector with our own subclass to dynamically modify what properties we want to show.
        [builder overrideClass:PSPDFAnnotationStyleViewController.class withClass:PSCSimpleAnnotationStyleViewController.class];
    }]];

    // We use the delegate to customize the menu items.
    pdfController.delegate = self;

    return pdfController;
}

#pragma mark - PSPDFViewControllerDelegate

// Limit the menu options for selected highlight annotations, as they don't use the annotation inspector.
- (NSArray<PSPDFMenuItem *> *)pdfViewController:(PSPDFViewController *)pdfController shouldShowMenuItems:(NSArray<PSPDFMenuItem *> *)menuItems atSuggestedTargetRect:(CGRect)rect forAnnotations:(NSArray<PSPDFAnnotation *> *)annotations inRect:(CGRect)annotationRect onPageView:(PSPDFPageView *)pageView {
    return [menuItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(PSPDFMenuItem *menuItem, NSDictionary *bindings) {
        // Only allow the remove, opacity, and color menus.
        return [@[PSPDFAnnotationMenuRemove, PSPDFAnnotationMenuOpacity] containsObject:(NSString *)menuItem.identifier] || [menuItem.identifier hasPrefix:PSPDFAnnotationMenuColor];
    }]];
}

// Limit the menu options when text is selected.
- (NSArray<PSPDFMenuItem *> *)pdfViewController:(PSPDFViewController *)pdfController shouldShowMenuItems:(NSArray<PSPDFMenuItem *> *)menuItems atSuggestedTargetRect:(CGRect)rect forSelectedText:(NSString *)selectedText inRect:(CGRect)textRect onPageView:(PSPDFPageView *)pageView {
    return [menuItems filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(PSPDFMenuItem *menuItem, NSDictionary *bindings) {
        return [@[PSPDFTextMenuCopy, PSPDFTextMenuDefine, PSPDFAnnotationMenuHighlight] containsObject:(NSString *)menuItem.identifier];
    }]];
}

@end

#pragma mark - PSCSimpleAnnotationStyleViewController

@implementation PSCSimpleAnnotationStyleViewController

- (NSArray<NSArray<PSPDFAnnotationStyleKey> *> *)propertiesForAnnotations:(NSArray<PSPDFAnnotation *> *)annotations {
    NSArray<NSArray<PSPDFAnnotationStyleKey> *> *defaultSections = [super propertiesForAnnotations:annotations];

    // Allow only a smaller list of known properties in the inspector popover.
    NSSet<PSPDFAnnotationStyleKey> *supportedKeys = [NSSet setWithObjects:PSPDFAnnotationStyleKeyColor, PSPDFAnnotationStyleKeyAlpha, PSPDFAnnotationStyleKeyLineWidth, PSPDFAnnotationStyleKeyFontSize, nil];

    NSMutableArray<NSArray<PSPDFAnnotationString> *> *newSections = [NSMutableArray array];
    for (NSArray *properties in defaultSections) {
        [newSections addObject:[properties filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *property, NSDictionary *bindings2) {
            return [supportedKeys containsObject:property];
        }]]];
    }
    return newSections;
}

@end
