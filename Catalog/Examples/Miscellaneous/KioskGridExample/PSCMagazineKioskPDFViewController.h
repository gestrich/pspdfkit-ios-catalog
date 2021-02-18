//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCKioskPDFViewController.h"

@class PSCMagazine;

NS_ASSUME_NONNULL_BEGIN

@interface PSCMagazineKioskPDFViewController : PSCKioskPDFViewController

/// Referenced magazine; just a cast to .document.
@property (nonatomic, readonly, nullable) PSCMagazine *magazine;

@end

NS_ASSUME_NONNULL_END
