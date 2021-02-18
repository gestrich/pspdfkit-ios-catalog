//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCMagazineKioskPDFViewController.h"

#import "PSCMagazine.h"

@implementation PSCMagazineKioskPDFViewController

#pragma mark - Lifecycle

- (instancetype)initWithDocument:(PSPDFDocument *)document configuration:(PSPDFConfiguration *)configuration {
    if ((self = [super initWithDocument:document configuration:configuration])) {
        // Restore viewState.
        if ([self.document isKindOfClass:PSCMagazine.class]) {
            PSPDFViewState *savedState = ((PSCMagazine *)self.document).lastViewState;
            [self applyViewState:savedState animateIfPossible:NO];
        }
    }
    return self;
}

- (PSCMagazine *)magazine {
    return (PSCMagazine *)self.document;
}

#pragma mark - UIViewController

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    // Save current viewState.
    if ([self.document isKindOfClass:PSCMagazine.class]) {
        ((PSCMagazine *)self.document).lastViewState = [self viewState];
    }
}

@end
