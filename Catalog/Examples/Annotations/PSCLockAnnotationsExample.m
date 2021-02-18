//
//  Copyright © 2014-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCAssetLoader.h"
#import "PSCExample.h"
#import "PSCFileHelper.h"
#import "PSPDFInkAnnotation+PSCSamples.h"

@interface PSCLockAnnotationsExample : PSCExample
@end

@implementation PSCLockAnnotationsExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Generate a new file with locked annotations";
        self.contentDescription = @"Uses the annotation flags to create a locked copy.";
        self.category = PSCExampleCategoryAnnotations;
        self.priority = 1000;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    NSURL *samplesURL = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"Samples"];
    NSURL *documentURL = [samplesURL URLByAppendingPathComponent:PSCAssetNameJKHF];
    NSURL *writableDocumentURL = PSCCopyFileURLToDocumentFolderAndOverride(documentURL, NO);

    // Copy the document to the temp directory.
    NSURL *tempURL = PSCTempFileURLWithPathExtension([NSString stringWithFormat:@"locked_%@", writableDocumentURL.lastPathComponent], @"pdf");
    if ([NSFileManager.defaultManager fileExistsAtPath:(NSString *)writableDocumentURL.path]) {
        [NSFileManager.defaultManager copyItemAtURL:writableDocumentURL toURL:tempURL error:NULL];
    } else {
        [NSFileManager.defaultManager copyItemAtURL:documentURL toURL:tempURL error:NULL];
    }

    // Open the new file and modify the annotations to be locked.
    PSPDFDocument *document = [[PSPDFDocument alloc] initWithURL:tempURL];
    document.annotationSaveMode = PSPDFAnnotationSaveModeEmbedded;

    // Create at least one annotation if the document is currently empty.
    if ([document annotationsForPageAtIndex:0 type:PSPDFAnnotationTypeAll & ~PSPDFAnnotationTypeLink].count == 0) {
        PSPDFInkAnnotation *ink = [PSPDFInkAnnotation psc_sampleInkAnnotationInRect:CGRectMake(100.0, 100.0, 200.0, 200.0)];
        ink.color = [UIColor colorWithRed:0.667 green:0.279 blue:0.748 alpha:1.0];
        ink.pageIndex = 0;
        [document addAnnotations:@[ink] options:nil];
    }

    // Lock all annotations except links and forms/widgets.
    for (NSUInteger pageIndex = 0; pageIndex < document.pageCount; pageIndex++) {
        NSArray<PSPDFAnnotation *> *annotations = [document annotationsForPageAtIndex:pageIndex type:PSPDFAnnotationTypeAll & ~(PSPDFAnnotationTypeLink | PSPDFAnnotationTypeWidget)];
        for (PSPDFAnnotation *annotation in annotations) {
            // Preserve existing flags, just set the locked and locked contents flags.
            annotation.flags |= PSPDFAnnotationFlagLocked | PSPDFAnnotationFlagLockedContents;
        }
    }

    // Save the document.
    [document saveWithOptions:nil error:nil];

    NSLog(@"Locked file: %@", tempURL.path);

    PSPDFViewController *pdfController = [[PSPDFViewController alloc] initWithDocument:document];
    return pdfController;
}

@end
