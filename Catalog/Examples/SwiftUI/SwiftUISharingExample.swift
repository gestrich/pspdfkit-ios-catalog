//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import SwiftUI
import PSPDFKitUI

class SwiftUISharingExample: Example {

    override init() {
        super.init()

        title = "SwiftUI with Customized Sharing Experience"
        contentDescription = "Set custom delegates to presented view controllers on-the-fly"
        category = .swiftUI
        priority = 50

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

/// Standalone delegate handler to customize the title
class DocumentSharingHandler: StandaloneDelegate, PDFDocumentSharingViewControllerDelegate {
    func documentSharingViewController(_ shareController: PDFDocumentSharingViewController, filenameForGeneratedFileFor sharingDocument: Document, destination: DocumentSharingConfiguration.Destination) -> String? {
        return "NewName"
    }
}

@available(iOS 13.0, *)
private struct SwiftUIExampleView: View {
    @ObservedObject var document: Document

    var body: some View {
        return VStack {
            PDFView(document: _document)
                .useParentNavigationBar(true) // Access outer navigation bar from the catalog
                .onDidShowController { controller, _, _ in
                    guard let sharingController = controller as? PDFDocumentSharingViewController else { return }
                    // The StandaloneDelegateContainer will automatically manage the lifetime of this helper
                    // It will be deallocated as soon as sharingController is deallocated.
                    let handler = DocumentSharingHandler(delegateTarget: sharingController)
                    sharingController.delegate = handler
                }
        }
        // Prevent jumping of the content as we show/hide the navigation bar
        .edgesIgnoringSafeArea(.all)
    }
}
