//
//  Copyright © 2014-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCAssetLoader.h"
#import "PSCExample.h"
#import "UIBarButtonItem+PSCBlockSupport.h"
#import <objc/runtime.h>

@interface PSCAnnotationCell : PSPDFAnnotationCell
@property (nonatomic) UIButton *shareButton;
- (void)updateShareButton;
@end

@interface PSCAnnotationTableViewController : PSPDFAnnotationTableViewController
+ (BOOL)isAnnotationShared:(PSPDFAnnotation *)annotation;
+ (void)toggleAnnotationSharingStatus:(PSPDFAnnotation *)annotation;
@end

@interface PSCAnnotationToolbar : PSPDFAnnotationToolbar
@end
@interface PSCCustomAnnotationStateManager : PSPDFAnnotationStateManager
@end

@interface PSCAnnotationCellExample : PSCExample
@end
@implementation PSCAnnotationCellExample

- (instancetype)init {
    if ((self = [super init])) {
        self.title = @"Subclassing PSPDFAnnotationCell";
        self.contentDescription = @"Customize the annotation cell in PSPDFAnnotationTableViewController";
        self.category = PSCExampleCategoryViewCustomization;
        self.priority = 70;
    }
    return self;
}

- (nullable UIViewController *)invokeWithDelegate:(id<PSCExampleRunnerDelegate>)delegate {
    PSPDFDocument *document = [PSCAssetLoader documentWithName:PSCAssetNameQuickStart];
    PSPDFViewController *pdfController = [[PSPDFViewController alloc] initWithDocument:document configuration:[PSPDFConfiguration configurationWithBuilder:^(PSPDFConfigurationBuilder *builder) {
        // Register the class overrides.
        [builder overrideClass:PSPDFAnnotationCell.class withClass:PSCAnnotationCell.class];
        [builder overrideClass:PSPDFAnnotationTableViewController.class withClass:PSCAnnotationTableViewController.class];

        [builder overrideClass:PSPDFAnnotationToolbar.class withClass:PSCAnnotationToolbar.class];
        [builder overrideClass:PSPDFAnnotationStateManager.class withClass:PSCCustomAnnotationStateManager.class];
    }]];
    pdfController.documentInfoCoordinator.availableControllerOptions = @[PSPDFDocumentInfoOptionAnnotations];

    // Automate pressing the outline button.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        psc_targetActionBlock(pdfController.outlineButtonItem.target, pdfController.outlineButtonItem.action)(nil);
    });

    return pdfController;
}

@end

#pragma mark - PSCCustomAnnotationCell

// Note: The UI here isn't great. I would recommend a smaller sharing *indicator* and using a "More" button to actually enable/disable sharing, but I wanted to present both ways (including how to add a button to the cell) to make the example more interesting.
@implementation PSCAnnotationCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        // Add sharing button
        _shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_shareButton setTitleColor:[UIColor colorWithRed:0.9 green:0.0 blue:0.0 alpha:1.0] forState:UIControlStateNormal];
        [_shareButton setTitleColor:[UIColor colorWithRed:0.7 green:0.0 blue:0.0 alpha:1.0] forState:UIControlStateHighlighted];
        self.accessoryView = _shareButton;
    }
    return self;
}

#pragma mark - PSPDFAnnotationCell

- (void)setAnnotation:(PSPDFAnnotation *)annotation {
    super.annotation = annotation;
    [self updateShareButton];
}

- (void)prepareForReuse {
    [super prepareForReuse];

    // Clear all targets.
    [self.shareButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    // There's no implicit animation block, so we have to animate manually.
    [UIView animateWithDuration:animated ? 0.3 : 0.0 animations:^{
        self.shareButton.alpha = editing ? 0.0 : 1.0;
    }];
}

- (void)layoutSubviews {
    [self updateShareButton];
    [super layoutSubviews];
}

#pragma mark - Share Button Update Logic

- (void)updateShareButton {
    const BOOL isShared = [PSCAnnotationTableViewController isAnnotationShared:self.annotation];
    [self.shareButton setTitle:isShared ? @"Unshare" : @"Share" forState:UIControlStateNormal];

    // Update frame
    [self.shareButton sizeToFit];
}

@end

#pragma mark - PSCCustomAnnotationTableViewController

@implementation PSCAnnotationTableViewController

#pragma mark - Sharing Helper

static NSString *const PSCSharedKey = @"shared";

// Obviously, it's not a good idea to use `userInfo` for this, but it works for this example to show class override.
+ (BOOL)isAnnotationShared:(PSPDFAnnotation *)annotation {
    if (!annotation) return NO;
    return [objc_getAssociatedObject(annotation, &PSCSharedKey) boolValue];
}

+ (void)setAnnotationShared:(PSPDFAnnotation *)annotation sharingStatus:(BOOL)sharingStatus {
    if (!annotation) return;
    objc_setAssociatedObject(annotation, &PSCSharedKey, @(sharingStatus), OBJC_ASSOCIATION_COPY);
}

+ (void)toggleAnnotationSharingStatus:(PSPDFAnnotation *)annotation {
    BOOL isShared = [self isAnnotationShared:annotation];
    [self setAnnotationShared:annotation sharingStatus:!isShared];
}

#pragma mark - UITableViewDelegate/DataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PSCAnnotationCell *cell = (PSCAnnotationCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];

    // Configure cell, connect the button.
    [cell.shareButton addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    return cell;
}

// NOTE: For the sake of a short and clear example, we're using a shortcut here with API that is not documented.
// See https://gist.github.com/steipete/10541433 for more details and possible better solutions.
- (NSString *)tableView:(UITableView *)tableView titleForSwipeAccessoryButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    PSPDFAnnotation *annotation = [self annotationForIndexPath:indexPath inTableView:tableView];
    const BOOL isShared = [self.class isAnnotationShared:annotation];
    return isShared ? @"Unshare" : @"Share";
}

- (void)tableView:(UITableView *)tableView swipeAccessoryButtonPushedForRowAtIndexPath:(NSIndexPath *)indexPath {
    // Invert the share property.
    PSPDFAnnotation *annotation = [self annotationForIndexPath:indexPath inTableView:tableView];
    [self.class toggleAnnotationSharingStatus:annotation];

    // Trigger update of the share indicator.
    PSCAnnotationCell *cell = (PSCAnnotationCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell updateShareButton];

    // Hide the Share/Delete menu.
    [self setEditing:NO animated:YES];
}

#pragma mark - Private Button Action

- (void)shareButtonPressed:(id)sender {
    // Crawl up the hierarchy to find the cell.
    PSCAnnotationCell *cell = sender;
    while (![cell isKindOfClass:PSCAnnotationCell.class]) {
        cell = (PSCAnnotationCell *)cell.superview;
    }

    // Toggle the state.
    PSPDFAnnotation *annotation = cell.annotation;
    if (annotation) {
        [PSCAnnotationTableViewController toggleAnnotationSharingStatus:annotation];
        [cell updateShareButton];

        // Just in case, end editing.
        [self setEditing:NO animated:YES];
    }
}

@end

#pragma mark - PSCCustomannotationToolbar

@implementation PSCAnnotationToolbar

- (instancetype)initWithAnnotationStateManager:(PSPDFAnnotationStateManager *)annotationStateManager {
    return [super initWithAnnotationStateManager:annotationStateManager];
}

@end

#pragma mark - PSCCustomAnnotationStateManager

@implementation PSCCustomAnnotationStateManager

- (BOOL)stateShowsStylePicker:(NSString *)state {
    return NO;
}

@end
