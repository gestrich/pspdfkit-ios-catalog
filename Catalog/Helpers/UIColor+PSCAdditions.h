//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (PSCAdditions)

/// Create a dynamic color with one color being used in light mode, and the other one
/// in dark mode. Defaults to light mode prior to iOS 13.
///
/// @param lightModeColor Color to be used in light mode and prior to iOS 13.
/// @param darkModeColor Color to be used in dark mode.
///
/// @return A dynamic color.
+ (UIColor *)psc_colorForLightMode:(UIColor *)lightModeColor darkMode:(UIColor *)darkModeColor;

@end

NS_ASSUME_NONNULL_END
