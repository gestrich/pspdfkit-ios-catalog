//
//  Copyright © 2016-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

/// The page grabber will be deprecated in a future release because the scroll
/// indicator from `UIScrollView` supports dragging on iOS 13 and later.
class PageGrabberExample: Example {

    override init() {
        super.init()

        title = "Page Grabber"
        contentDescription = "Show a page grabber to quickly skim through pages."
        category = .controllerCustomization
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(withName: .quickStart)

        let controller = PDFViewController(document: document) {
            // Enable the page grabber:
            $0.isPageGrabberEnabled = true
            // This is not necessary, but the grabber is especially useful in this mode:
            $0.pageTransition = .scrollContinuous
            $0.scrollDirection = .vertical
        }

        // change the tint color, or even set a custom view.
        controller.pageGrabberController!.pageGrabber.grabberView.tintColor = UIColor.purple

        return controller
    }
}
