//
//  Copyright © 2012-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import <Availability.h>

// This release supports Mac Catalyst without the Big Sur SDK. Xcode build 12A7209.
#if !defined(__IPHONE_14_0) && !TARGET_OS_MACCATALYST
#warning PSPDFKit 10 has been designed for Xcode 12 with SDK 14. Other combinations are not supported.
#endif

NS_ASSUME_NONNULL_BEGIN

@interface PSCAppDelegate : UIResponder <UIApplicationDelegate>
@end

NS_ASSUME_NONNULL_END
