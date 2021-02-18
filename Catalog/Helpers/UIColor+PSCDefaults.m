//
//  Copyright © 2013-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "UIColor+PSCDefaults.h"

#import "PSCMacros.h"

@implementation UIColor (PSCDefaults)

+ (UIColor *)psc_catalogTintColor {
    if (@available(iOS 13, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor* (UITraitCollection *traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return [UIColor colorWithRed:0.660 green:0.750 blue:0.970 alpha:1.0];
            } else {
                return [UIColor colorWithRed:0.270 green:0.210 blue:0.890 alpha:1.0];
            }
        }];
    } else {
        return [UIColor colorWithRed:0.270 green:0.210 blue:0.890 alpha:1.0];
    }
}

+ (UIColor *)psc_textColor {
    if (@available(iOS 13, *)) {
        return UIColor.labelColor;
    } else {
        return UIColor.blackColor;
    }
}

+ (UIColor *)psc_secondaryTextColor {
    if (@available(iOS 13, *)) {
        return UIColor.secondaryLabelColor;
    } else {
        return UIColor.darkGrayColor;
    }
}

+ (UIColor *)psc_accessoryViewColor {
    if (@available(iOS 13, *)) {
        // We are not using systemFillColor as it has a lower alpha compared to one on iOS 12.
        return UIColor.systemGray3Color;
    } else {
        return [UIColor colorWithWhite:0.3 alpha:0.3];
    }
}

+ (UIColor *)psc_systemBackgroundColor {
    if (@available(iOS 13, *)) {
        return UIColor.systemBackgroundColor;
    } else {
        return UIColor.whiteColor;
    }
}

+ (UIColor *)psc_secondarySystemBackgroundColor {
    if (@available(iOS 13, *)) {
        return UIColor.secondarySystemBackgroundColor;
    } else {
        return UIColor.whiteColor;
    }
}

+ (UIColor *)psc_systemGroupedBackgroundColor {
    if (@available(iOS 13, *)) {
        return UIColor.systemGroupedBackgroundColor;
    } else {
        PSC_CATALYST_DEPRECATED_NOWARN(return UIColor.groupTableViewBackgroundColor;)
    }
}

+ (UIColor *)psc_tertiarySystemFillColor {
    if (@available(iOS 13, *)) {
        return UIColor.tertiarySystemFillColor;
    } else {
        return [UIColor colorWithRed:0.46 green:0.46 blue:0.60 alpha:0.12];
    }
}

@end
