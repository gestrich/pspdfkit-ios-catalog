//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

#import "PSCApplication.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PSCApplication

- (void)sendEvent:(UIEvent *)event {
    [super sendEvent:event];

    /// Detect Apple Pencil availability.
    ///
    /// There is no simple way to know whether a device supports Apple Pencil.
    /// All an app knows is that if it receives a touch event of type `pencil` then an Apple Pencil was connected at that time.
    /// For more details check: https://pspdfkit.com/guides/ios/current/annotations/apple-pencil/#apple-pencil-availability
    PSPDFApplePencilManager *applePencilManager = PSPDFKitGlobal.sharedInstance.applePencilManager;

    if (applePencilManager.detected || event.type != UIEventTypeTouches) {
        return;
    }

    NSSet <UITouch *> *touches = event.allTouches;
    if (touches.count == 0) {
        return;
    }

    for (UITouch *touch in touches) {
        if (touch.type == UITouchTypePencil && touch.phase == UITouchPhaseBegan) {
            applePencilManager.detected = true;
        }
    }
}

@end

NS_ASSUME_NONNULL_END
