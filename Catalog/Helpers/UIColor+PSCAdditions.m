//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "UIColor+PSCAdditions.h"

@implementation UIColor (PSCAdditions)

+ (UIColor *)psc_colorForLightMode:(UIColor *)lightModeColor darkMode:(UIColor *)darkModeColor {
    if (@available(iOS 13, *)) {
        return [UIColor colorWithDynamicProvider:^ UIColor *(UITraitCollection *traitCollection) {
            if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return darkModeColor;
            } else {
                return lightModeColor;
            }
        }];
    } else {
        return lightModeColor;
    }
}

@end
