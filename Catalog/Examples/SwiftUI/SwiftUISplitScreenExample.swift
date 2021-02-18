//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import SwiftUI
import PSPDFKitUI

class SwiftUISplitScreenExample: Example {

    override init() {
        super.init()

        title = "SwiftUI SplitScreen Example"
        contentDescription = "Shows how to show two PDFViewController in SwiftUI side by side."
        category = .swiftUI
        priority = 13

        // Do not show the example in the list if running on iOS 12.
        if #available(iOS 13, *) {} else {
            targetDevice = []
        }
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        if #available(iOS 13, *) {
            let leadingDocument = AssetLoader.writableDocument(withName: .quickStart, overrideIfExists: false)
            let trailingDocument = AssetLoader.writableDocument(withName: .annualReport, overrideIfExists: false)
            let swiftUIView = SwiftUISplitScreenExampleView(leadingDocument: leadingDocument, trailingDocument: trailingDocument)
            let hostingController = UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
            hostingController.title = "SwiftUI SplitScreen Example"
            return hostingController
        }
        return nil
    }
}

@available(iOS 13.0, *)
private struct SwiftUISplitScreenExampleView: View {
    @ObservedObject var leadingDocument: Document
    @ObservedObject var trailingDocument: Document

    var body: some View {
        HStack(spacing: 0) {
            // First view uses continuous vertical scrolling.
            NavigationView {
                PDFView(document: _leadingDocument)
                    .useParentNavigationBar(true) // Access outer navigation bar from the catalog
                    .scrollDirection(.vertical)
                    .pageTransition(.scrollContinuous)
                    .pageMode(.single)
                    .spreadFitting(.fill)
                    .userInterfaceViewMode(.always)
                    // If you can require iOS 14, use this API instead.
                    // .navigationBarTitleDisplayMode(.inline)
                    .navigationBarTitle(LocalizedStringKey(leadingDocument.title!), displayMode: .inline)

            }.navigationViewStyle(StackNavigationViewStyle())

            Divider()

            // Second view uses horizontal per-page scrolling.
            NavigationView {
                PDFView(document: _trailingDocument)
                    .useParentNavigationBar(true) // Access outer navigation bar from the catalog
                    .scrollDirection(.horizontal)
                    .pageTransition(.scrollPerSpread)
                    .pageMode(.single)
                    .spreadFitting(.fill)
                    .userInterfaceViewMode(.always)
                    .navigationBarTitle(LocalizedStringKey(trailingDocument.title!), displayMode: .inline)
            }.navigationViewStyle(StackNavigationViewStyle())
        }
    }
}

// MARK: Previews

@available(iOS 13.0, *)
struct SwiftUISplitScreenExamplePreviews: PreviewProvider {
    static var previews: some View {
        let leadingDocument = AssetLoader.document(withName: .quickStart)
        let trailingDocument = AssetLoader.document(withName: .annualReport)
        SwiftUISplitScreenExampleView(leadingDocument: leadingDocument, trailingDocument: trailingDocument)
    }
}
