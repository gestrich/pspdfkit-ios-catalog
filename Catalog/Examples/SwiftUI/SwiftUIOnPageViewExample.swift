//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import SwiftUI
import PSPDFKitUI

class SwiftUIOnPageViewExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()

        title = "Using SwiftUI on a page"
        contentDescription = "Shows how to add a SwiftUI view embedded on a page view."
        category = .swiftUI
        priority = 20

        // Do not show the example in the list if running on iOS 12.
        if #available(iOS 13, *) {} else {
            targetDevice = []
        }
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(withName: .quickStart, overrideIfExists: false)
        let controller = PDFViewController(document: document) { builder in
            if #available(iOS 13.0, *) {
                builder.overrideClass(PDFPageView.self, with: ButtonPageView.self)
            }
        }
        controller.delegate = self
        return controller
    }

    func pdfViewController(_ pdfController: PDFViewController, didConfigurePageView pageView: PDFPageView, forPageAt pageIndex: Int) {
        guard #available(iOS 13.0, *) else { return }
        guard let buttonPageView = pageView as? ButtonPageView else { return }

        let hostingController = UIHostingController(rootView: PageButton(pageIndex: buttonPageView.pageIndex))
        hostingController.view.backgroundColor = UIColor.clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        pdfController.documentViewController?.addChild(hostingController)
        buttonPageView.addSubview(hostingController.view)
        hostingController.didMove(toParent: pdfController.documentViewController)

        NSLayoutConstraint.activate([
            hostingController.view.centerXAnchor.constraint(equalTo: buttonPageView.centerXAnchor),
            hostingController.view.centerYAnchor.constraint(equalTo: buttonPageView.centerYAnchor),
        ])

        buttonPageView.hostingController = hostingController
    }
}

@available(iOS 13.0, *)
private class ButtonPageView: PDFPageView {
    fileprivate var hostingController: UIHostingController<PageButton>?

    override func prepareForReuse() {
        super.prepareForReuse()
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
    }
}

@available(iOS 13.0, *)
private struct PageButton: View {
    @State var showAlert = false
    let pageIndex: PageIndex

    var body: some View {
        Button(action: {
            self.showAlert = true
        }, label: {
            Text("Page \(pageIndex + 1)")
        })
        .font(.headline)
        .padding()
        .background(Color.accentColor)
        .cornerRadius(10)
        .foregroundColor(.white)
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Tapped on page \(pageIndex + 1)"))
        }
        .edgesIgnoringSafeArea(.all)
    }
}
