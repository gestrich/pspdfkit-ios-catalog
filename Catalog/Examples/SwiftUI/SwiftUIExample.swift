//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import SwiftUI
import PSPDFKitUI

class SwiftUIExample: Example {

    override init() {
        super.init()

        title = "SwiftUI Example"
        contentDescription = "Shows how to show a PDFViewController in SwiftUI."
        category = .swiftUI
        priority = 10

        // Do not show the example in the list if running on iOS 12.
        if #available(iOS 13, *) {} else {
            targetDevice = []
        }
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        if #available(iOS 13, *) {
            let document = AssetLoader.writableDocument(withName: .quickStart, overrideIfExists: false)
            let swiftUIView = SwiftUIExampleView(document: document)
            return UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
        }
        return nil
    }
}

@available(iOS 13.0, *)
private struct SwiftUIExampleView: View {
    @ObservedObject var document: Document

    var body: some View {
        return VStack {

            PDFView(document: _document)
                .scrollDirection(.vertical)
                .pageTransition(.scrollContinuous)
                .pageMode(.single)
                .spreadFitting(.fill)
                .useParentNavigationBar(true) // Access outer navigation bar from the catalog
                .updateControllerConfiguration { controller in
                    controller.navigationItem.setRightBarButtonItems([controller.thumbnailsButtonItem,
                                                                      controller.annotationButtonItem,
                                                                      controller.readerViewButtonItem],
                                                                     for: .document, animated: false)
                }
        }
        // Prevent jumping of the content as we show/hide the navigation bar
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: Previews

@available(iOS 13.0, *)
struct SwiftUIExamplePreviews: PreviewProvider {
    static var previews: some View {
        let document = AssetLoader.document(withName: .quickStart)
        SwiftUIExampleView(document: document)
    }
}
