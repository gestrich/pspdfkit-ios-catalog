//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

extension UIImage {

    /// Creates a colored image with optional rounded corners.
    @objc public class func psc_image(color: UIColor, size: CGSize) -> UIImage {
        let rect = CGRect(origin: CGPoint.zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(rect)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    @objc(psc_imageNamed:) public class func psc_image(named name: String) -> UIImage? {
        let bundle = Bundle(for: PSCCatalogViewController.self)
        return self.init(named: name, in: bundle, compatibleWith: nil)
    }
}
