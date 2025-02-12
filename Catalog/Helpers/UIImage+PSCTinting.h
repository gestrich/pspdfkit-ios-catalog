//
//  Copyright © 2013-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (PSCTinting)

- (nullable UIImage *)psc_imageTintedWithColor:(UIColor *)color fraction:(CGFloat)fraction;

@end

NS_ASSUME_NONNULL_END
