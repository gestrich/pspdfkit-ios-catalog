//
//  Copyright © 2013-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (PSCDefaults)

/// Dynamic brand color on iOS 13.
/// Falls back to a static color on iOS 12. Same as light mode color on iOS 13.
@property (class, nonatomic, readonly) UIColor *psc_catalogTintColor;

/// Gives `UIColor.labelColor` on iOS 13.
/// Falls back to black color on version prior iOS 13.
@property (class, nonatomic, readonly) UIColor *psc_textColor;

/// `UIColor.secondaryLabelColor` on iOS 13.
/// Falls back to dark gray color on version prior iOS 13.
@property (class, nonatomic, readonly) UIColor *psc_secondaryTextColor;

/// `UIColor.systemGray3Color` on iOS 13.
/// Falls back to a light gray color ([UIColor colorWithWhite:0.3 alpha:0.3]) on version prior iOS 13.
@property (class, nonatomic, readonly) UIColor *psc_accessoryViewColor;

/// `UIColor.systemBackgroundColor` on iOS 13.
/// Falls back to white color on earlier versions.
@property (class, nonatomic, readonly) UIColor *psc_systemBackgroundColor;

/// `UIColor.secondarySystemBackgroundColor` on iOS 13.
/// Falls back to white color on earlier versions.
@property (class, nonatomic, readonly) UIColor *psc_secondarySystemBackgroundColor;

/// `UIColor.systemGroupedBackgroundColor` on iOS 13.
/// Falls back to `UIColor.groupTableViewBackgroundColor` on earlier versions.
@property (class, nonatomic, readonly) UIColor *psc_systemGroupedBackgroundColor;

/// `UIColor.tertiarySystemFillColor` on iOS 13.
/// Falls back to RGB values of `tertiarySystemFillColor` in light mode on earlier versions.
@property (class, nonatomic, readonly) UIColor *psc_tertiarySystemFillColor;

@end

NS_ASSUME_NONNULL_END
