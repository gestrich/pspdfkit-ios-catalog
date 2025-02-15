//
//  Copyright © 2015-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'PlaygroundExample.swift' for the Swift version of this example.

#import "PSCAssetLoader.h"
#import "PSCExample.h"
#import "PSCFileHelper.h"
#import "PSCKioskPDFViewController.h"

@interface PSCPlaygroundExample : PSCExample
@end
@implementation PSCPlaygroundExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"PDFViewController Playground";
        self.contentDescription = @"Start here";
        self.type = @"com.pspdfkit.catalog.playground";
        self.category = PSCExampleCategoryTop;
        self.priority = 1;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    // Playground is convenient for testing.
    PSPDFDocument *document = [PSCAssetLoader writableDocumentWithName:PSCAssetNameQuickStart overrideIfExists:NO];

    PSPDFConfiguration *configuration = [PSPDFConfiguration configurationWithBuilder:^(PSPDFConfigurationBuilder *builder) {
        // Use the configuration to set main PSPDFKit options.
        builder.pageTransition = PSPDFPageTransitionScrollPerSpread;
    }];

    PSPDFViewController *controller = [[PSCKioskPDFViewController alloc] initWithDocument:document configuration:configuration];
    return controller;
}

@end
