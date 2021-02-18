//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class OnlyAllowInkSigningExample: Example {

    override init() {
        super.init()
        title = "Only allow adding ink signatures, no digital signatures."
        contentDescription = "Shows how to disable digital signatures modification and only allow adding ink signatures."
        category = .forms
        priority = 26
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(withName: "Form_example.pdf", overrideIfExists: true)
        document.annotationSaveMode = .embedded

        let controller = PDFViewController(document: document) {
            $0.signatureCertificateSelectionMode = .never
            $0.allowRemovingDigitalSignatures = false
        }

        // Remove any stored signatures.
        controller.configuration.signatureStore.signatures = []

        return controller
    }
}
