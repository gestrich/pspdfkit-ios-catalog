//
//  Copyright © 2017-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

/// Shows how to use the Document Processor to remove password protection from a
/// document. When printing a password protected document, the system printing
/// dialog will ask the user for the password before printing. To work around
/// this, we first create a duplicate PDF file without the password, and then
/// use that file to print.
///
/// Document Permissions guide:
/// https://pspdfkit.com/guides/ios/current/features/document-permissions

class RemovePasswordExample: Example {

    override init() {
        super.init()
        title = "Remove password protection from document"
        contentDescription = "Example shows how to use the document processor to remove password protection from a document."
        category = .security
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.document(withName: AssetName(rawValue: "protected.pdf"))
        let outputURL = TempFileURLWithPathExtension(prefix: "unlocked", pathExtension: "pdf")
        removePasswordProtectionFromDocument(document: document, password: "test123", outputURL: outputURL)

        let unlockedDocument = Document(url: outputURL)
        return PDFViewController(document: unlockedDocument)
    }

    func removePasswordProtectionFromDocument(document: Document, password: String, outputURL: URL) {
        // We need to unlock the document before doing anything else.
        document.unlock(withPassword: password)

        do {
            // Create a processor configuration and document security options.
            guard let processorConfiguration = Processor.Configuration(document: document) else {
                print("Error: Could not create a processor configuration.")
                return
            }

            // Here, we set the owner and user password to nil because we want to remove the password.
            let documentSecurityOptions = try Document.SecurityOptions(ownerPassword: nil, userPassword: nil, keyLength: Document.SecurityOptionsKeyLengthAutomatic, permissions: [.annotationsAndForms, .printing, .printHighQuality])

            // Create a processor and write the file with the permissions applied.
            let processor = Processor(configuration: processorConfiguration, securityOptions: documentSecurityOptions)
            try processor.write(toFileURL: outputURL)
        } catch {
            print(error)
        }
    }
}
