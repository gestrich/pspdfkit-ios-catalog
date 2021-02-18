//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

class CustomDigitalSignatureCoordinator: DigitalSignatureCoordinator {
    override func presentSignedDocument(_ signedDocument: Document, showingPageIndex pageIndex: PageIndex, with presentationContext: PresentationContext) {
        super.presentSignedDocument(signedDocument, showingPageIndex: pageIndex, with: presentationContext)

        let signedAnnotations = signedDocument.annotationsForPage(at: 0, type: Annotation.Kind.widget)
        let signedFormElement = signedAnnotations.filter({ annotation in
            return annotation.isKind(of: SignatureFormElement.self)
        }).first

        let signedSignatureFormElement = signedFormElement as! SignatureFormElement
        var privateKey: PrivateKey?
        let signatureManager = SDK.shared.signatureManager
        let p12signer = signatureManager.registeredSigners.first as! PKCS12Signer
        let p12 = p12signer.p12
        p12.unlock(withPassword: "test") { _, key, _ in
            privateKey = key
        }

        let biometricProperties = signedSignatureFormElement.signatureBiometricProperties(privateKey!)
        print("Biometric Properties")
        print("pressure list: \(biometricProperties?.pressureList ?? []))")
        print("time points: \(biometricProperties?.timePointsList ?? [])")
        print("touch radius: \(biometricProperties?.touchRadius ?? 0)")
        print("input mode: \(biometricProperties?.inputMethod ?? DrawInputMethod.none)")

        let alert = UIAlertController(title: "Biometric Properties", message: "See the console logs for the Biometric Properties.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default))

        // Wait for the "Signed" HUD to disappear.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            presentationContext.actionDelegate.present(alert, options: nil, animated: true, sender: nil)
        }
    }
}

class AccessDigitalSignatureBiometricPropertiesExample: Example {

    override init() {
        super.init()

        title = "Access Biometric Properties after digitally signing a document"
        contentDescription = "Password is 'test'"
        category = .forms
        priority = 40
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let p12URL = AssetLoader.assetURL(withName: "JohnAppleseed.p12")
        let p12data = try? Data(contentsOf: p12URL)
        let p12 = PKCS12(data: p12data!)
        let p12signer = PKCS12Signer(displayName: "John Appleseed", pkcs12: p12)
        let signatureManager = SDK.shared.signatureManager
        signatureManager.clearRegisteredSigners()
        signatureManager.register(p12signer)
        signatureManager.clearTrustedCertificates()

        // Add certs to trust store for the signature validation process
        let certURL = AssetLoader.assetURL(withName: "JohnAppleseed.p7c")
        let certData = try? Data(contentsOf: certURL)
        let certificates = try? X509.certificates(fromPKCS7Data: certData!)
        for x509 in certificates! {
            signatureManager.addTrustedCertificate(x509)
        }

        let document = AssetLoader.writableDocument(withName: "Form_example.pdf", overrideIfExists: false)

        let controller = PDFViewController(document: document) {
            $0.overrideClass(DigitalSignatureCoordinator.self, with: CustomDigitalSignatureCoordinator.self)
        }
        return controller
    }
}
