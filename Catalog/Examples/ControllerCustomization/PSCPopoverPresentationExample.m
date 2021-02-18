//
//  Copyright © 2015-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// See 'PopoverPresentationExample.swift' for the Swift version of this example.

#import "PSCAssetLoader.h"
#import "PSCExample.h"

@interface PopoverPresentationExample : PSCExample
@end
@implementation PopoverPresentationExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"PDFViewController in Popover";
        self.contentDescription = @"Uses a vanilla PDFViewController presented in a popover presentation controller.";
        self.category = PSCExampleCategoryControllerCustomization;
        self.wantsModalPresentation = YES;
        self.customizations = ^(UINavigationController *container) {
            container.modalPresentationStyle = UIModalPresentationPopover;
            container.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
        };
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    PSPDFDocument *document = [PSCAssetLoader documentWithName:PSCAssetNameJKHF];
    PSPDFViewController *controller = [[PSPDFViewController alloc] initWithDocument:document];
    controller.preferredContentSize = CGSizeMake(640, 480);
    return controller;
}

@end
