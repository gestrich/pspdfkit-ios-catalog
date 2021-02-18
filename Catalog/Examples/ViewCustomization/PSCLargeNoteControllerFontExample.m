//
//  Copyright © 2014-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCAssetLoader.h"
#import "PSCExample.h"

@interface PSCLargeFontNoteAnnotationViewController : PSPDFNoteAnnotationViewController
@end
@interface PSCLargeNoteControllerFontExample : PSCExample
@end
@implementation PSCLargeNoteControllerFontExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Custom Font for Comments";
        self.contentDescription = @"Shows how to customize the font for comments in the NoteAnnotationViewController.";
        self.category = PSCExampleCategoryViewCustomization;
        self.priority = 89;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    PSPDFDocument *document = [PSCAssetLoader documentWithName:PSCAssetNameQuickStart];
    PSPDFViewController *pdfController = [[PSPDFViewController alloc] initWithDocument:document configuration:[PSPDFConfiguration configurationWithBuilder:^(PSPDFConfigurationBuilder *builder) {
        [builder overrideClass:PSPDFNoteAnnotationViewController.class withClass:PSCLargeFontNoteAnnotationViewController.class];
    }]];

    // We create the appearance rule on the custom subclass to avoid changing the note controllers in other examples.
    [UITextView appearanceWhenContainedInInstancesOfClasses:@[PSCLargeFontNoteAnnotationViewController.class]].font = [UIFont fontWithName:@"Noteworthy" size:30.0];
    [UITextView appearanceWhenContainedInInstancesOfClasses:@[PSCLargeFontNoteAnnotationViewController.class]].textColor = UIColor.systemGreenColor;

    return pdfController;
}

@end

// Custom empty subclass of the PSPDFNoteAnnotationViewController to avoid polluting other examples, since UIAppearance can't be reset to the default.
@implementation PSCLargeFontNoteAnnotationViewController

- (void)updateTextView:(UITextView *)textView {
    // Possible to set the color here, but it's even cleaner to use UIAppearance rules (see above).
    // textView.font = [UIFont fontWithName:@"Futura" size:40.0];
    // textView.textColor = UIColor.brownColor;
}

@end
