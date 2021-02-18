//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import <PSPDFKit/PSPDFKit.h>
#import <PSPDFKitUI/PSPDFKitUI.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Main controller for PSPDF related examples.
PSPDF_EXPORT @interface PSCCatalogViewController : PSPDFBaseTableViewController

/// Show programming language indicators for examples as well as a preferred example language switch.
@property (nonatomic, assign) BOOL languageSelectionEnabled;

/// Determines if all sections should be shown in a single list. Defaults to NO.
@property (nonatomic, assign) BOOL shouldCombineSections;

/// A reference to the key window used for appearance styling.
@property (nonatomic, weak) UIWindow *window;

/// Open a specific example with a given example type from the Catalog.
/// Return YES if opening the example succeeded, NO otherwise.
- (BOOL)openExampleWithType:(NSString *)exampleType;

@end

NS_ASSUME_NONNULL_END
