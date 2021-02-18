//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

/// This example shows how to customize PSPDFKit such that documents with signature fields are always
/// signed cryptographically, and that documents with multiple signature fields — such as contracts —
/// can be signed in one go, without asking the user to unlock the certificate for each field they
/// sign.
class OnlyAllowDigitalSigningExample: Example, PDFViewControllerDelegate {

    override init() {
        super.init()
        title = "Only allow adding digital signatures: No ink signatures."
        contentDescription = "password: test"
        category = .forms
        priority = 25

        // There is no point in doing this more than once per app session
        resetTrust(SDK.shared.signatureManager)
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(withName: "Form_example.pdf", overrideIfExists: true)

        // Uncomment to showcase a flow where a contract needs to be signed in multiple places:
        // insertMultipleSignatureFields(document: document)

        /*
         Setup a shared signer instance, so that the user only needs to unlock the private key once,
         even if we sign multiple fields in the document.
         */
        Self.sharedSigner = {
            let PKCS12data = johnAppleseedCryptoData(type: "p12")
            return MemoizingPKCS12Signer(displayName: "John Appleseed", pkcs12: PKCS12(data: PKCS12data))
        }()

        let controller = PDFViewController(document: document) {
            // Replace SignatureViewController and DigitalSignatureCoordinator so we can customize the signing behavior
            $0.overrideClass(SignatureViewController.self, with: DigitalSignatureViewController.self)
            $0.overrideClass(DigitalSignatureCoordinator.self, with: InplacePresentingSignatureCoordinator.self)
            // Remove any stored signatures, so that each signature element has a unique appearance
            $0.signatureStore.signatures = []
        }
        // Become the delegate, so we can clear the shared signer when the view controller goes away
        controller.delegate = self

        return controller
    }

    /// The shared memoizing signer object, so that the user not have to type in their password
    /// repeatedly.
    /// We populate this in `invoke(with:)` and clear it in `pdfViewControllerDidDismiss(_:)`.
    static var sharedSigner: MemoizingPKCS12Signer?

    /// Clear the shared signer so that the unlocked private key does not stick around, and the user
    /// will be prompted for their password again, the next time they open this example.
    func pdfViewControllerDidDismiss(_ pdfController: PDFViewController) {
        Self.sharedSigner = nil
    }

    /// A DigitalSignatureCoordinator that displays the signed document in-place instead of pushing it
    /// on the navigation stack, preserving not only the current page, but also the viewport if the
    /// user zoomed in.
    /// This allows a more natural flow when signing multiple signature elements/fields in the same
    /// document.
    class InplacePresentingSignatureCoordinator: DigitalSignatureCoordinator {
        /// Replaces the currently visible document with the signed one, conserving the view state.
        override func presentSignedDocument(_ signedDocument: Document, showingPageIndex pageIndex: PageIndex, with presentationContext: PresentationContext) {
            let documentPresenter = presentationContext.pdfController
            let viewState = documentPresenter.viewState ?? PDFViewState(pageIndex: pageIndex)
            documentPresenter.document = signedDocument
            documentPresenter.applyViewState(viewState, animateIfPossible: false)
        }
    }

    /// Acts as a façade for an actual PKCS12Signer — which cannot be subclassed itself.
    ///
    /// The only interesting thing this class does is intercepting the unlocked certificate and private
    /// key of the actual signer, such that the user only has to enter their password once per app
    /// session, even when signing multiple signature fields.
    class MemoizingPKCS12Signer: PDFSigner {
        /// The actual signer to which we delegate almost all of the work
        private let actualSigner: PKCS12Signer
        /// The certificate captured in requestSigningCertificate(_:,completionBlock:)
        private var unlockedCertificate: X509?
        /// The private key captured in requestSigningCertificate(_:,completionBlock:)
        private var capturedPrivateKey: PrivateKey?

        required init(displayName: String, pkcs12: PKCS12) {
            actualSigner = PKCS12Signer(displayName: displayName, pkcs12: pkcs12)
            super.init()
        }
        required init?(coder: NSCoder) {
            fatalError("Not supported")
        }

        /// Requests a signing certificate and, upon success, reuses that certificate/private key for
        /// any later invocation of this method.
        ///
        /// This override prevents prompting the user for the password every time they want to sign
        /// a document with multiple signature fields and form elements, like contracts that require
        /// the same person to sign in multiple places.
        override func requestSigningCertificate(_ sourceController: Any, completionBlock: ((X509?, Swift.Error?) -> Void)? = nil) {
            if let certificate = unlockedCertificate, let privateKey = capturedPrivateKey {
                if actualSigner.privateKey == nil {
                    actualSigner.privateKey = privateKey
                }
                completionBlock?(certificate, nil)
            } else {
                actualSigner.requestSigningCertificate(sourceController) { certificate, error in
                    self.unlockedCertificate = certificate
                    self.capturedPrivateKey = self.actualSigner.privateKey
                    completionBlock?(certificate, error)
                }
            }
        }
    }

    /// A SignatureViewController that uses our shared signer instance, only allows the creation of
    /// digital signatures, and requires drawing a new signature in each field.
    class DigitalSignatureViewController: SignatureViewController {
        /// Use the same specific signer to force creating a digital signature, and avoid repeated
        /// password prompts.
        override var signer: PDFSigner? {
            OnlyAllowDigitalSigningExample.sharedSigner
        }

        /// Set the certificate selection mode to `.never` to disable the ability for users to select a different signer.
        override var certificateSelectionMode: SignatureCertificateSelectionMode {
            get { .never }
            // swiftlint:disable:next unused_setter_value
            set {}
        }

        /// Require that each signature is drawn individually, and never saved
        override var savingStrategy: SignatureSavingStrategy {
            get { .neverSave }
            // swiftlint:disable:next unused_setter_value
            set {}
        }
    }
}

// MARK: - Forwarding Overrides of the Custom Signer

extension OnlyAllowDigitalSigningExample.MemoizingPKCS12Signer {
    override var filter: String {
        actualSigner.filter
    }
    override var signatureType: PDFSignatureType {
        get { actualSigner.signatureType }
        set { actualSigner.signatureType = newValue }
    }
    override var displayName: String? {
        get { actualSigner.displayName }
        set { actualSigner.displayName = newValue }
    }
    override var signersName: String? {
        get { actualSigner.signersName }
        set { actualSigner.signersName = newValue }
    }
    override var reason: String? {
        get { actualSigner.reason }
        set { actualSigner.reason = newValue }
    }
    override var location: String? {
        get { actualSigner.location }
        set { actualSigner.location = newValue }
    }
    override var privateKey: PrivateKey? {
        get { actualSigner.privateKey }
        set { actualSigner.privateKey = newValue }
    }
    override var dataSource: PDFDocumentSignerDataSource? {
        get { actualSigner.dataSource }
        set { actualSigner.dataSource = newValue }
    }
    override var delegate: PDFDocumentSignerDelegate? {
        get { actualSigner.delegate }
        set { actualSigner.delegate = newValue }
    }
    override func prepare(_ element: SignatureFormElement, toBeSignedWith signatureAppearance: PDFSignatureAppearance, contents: PDFSignatureContents, writingTo dataSink: DataSink, completion completionBlock: @escaping PSPDFSignatureCreationBlock) {
        actualSigner.prepare(element, toBeSignedWith: signatureAppearance, contents: contents, writingTo: dataSink, completion: completionBlock)
    }
    override func embedSignature(in element: SignatureFormElement, with contents: PDFSignatureContents, writingTo dataSink: DataSink, completion completionBlock: @escaping PSPDFSignatureCreationBlock) {
        actualSigner.embedSignature(in: element, with: contents, writingTo: dataSink, completion: completionBlock)
    }
    override func sign(_ data: Data, privateKey: PrivateKey, hashAlgorithm: PDFSignatureHashAlgorithm) -> Data {
        actualSigner.sign(data, privateKey: privateKey, hashAlgorithm: hashAlgorithm)
    }
    override func sign(_ element: SignatureFormElement, withCertificate certificate: X509, writeTo dataSink: DataSink, completionBlock: ((Bool, DataSink?, Swift.Error?) -> Void)? = nil) {
        actualSigner.sign(element, withCertificate: certificate, writeTo: dataSink, completionBlock: completionBlock)
    }
    override func sign(_ element: SignatureFormElement, withCertificate certificate: X509, writeTo path: String, completionBlock: ((Bool, Document?, Swift.Error?) -> Void)? = nil) {
        actualSigner.sign(element, withCertificate: certificate, writeTo: path, completionBlock: completionBlock)
    }
}

// MARK: - Auxiliary Helper Functions

extension OnlyAllowDigitalSigningExample {
    private func resetTrust(_ signatureManager: PDFSignatureManager) {
        signatureManager.clearTrustedCertificates()

        // Add certs to trust store for the signature validation process
        let certificateData = johnAppleseedCryptoData(type: "p7c")
        let certificates = try! X509.certificates(fromPKCS7Data: certificateData)
        for x509 in certificates {
            signatureManager.addTrustedCertificate(x509)
        }
    }

    private func johnAppleseedCryptoData(type: String) -> Data {
        let fileURL = AssetLoader.assetURL(withName: AssetName(rawValue: "JohnAppleseed.\(type)"))

        return try! Data(contentsOf: fileURL)
    }

    private func insertMultipleSignatureFields(document: Document) {
        guard  let documentProvider = document.documentProviderForPage(at: 0),
            let pageInfo = document.pageInfoForPage(at: 0) else { fatalError("Page 0 must be valid.") }

        // Just make sure that the elements will be clearly visible…
        let availableSpace = pageInfo.cropBox.insetBy(dx: 60, dy: 60)
        for i in 1...4 {
            var signatureFrame = availableSpace
            signatureFrame.size.width /= 3
            signatureFrame.size.height /= 7
            if i % 2 != 1 {
                signatureFrame.origin.x += signatureFrame.width * 2
            }
            if i >= 3 {
                signatureFrame.origin.y += signatureFrame.height * 6
            }
            let element = SignatureFormElement()
            element.boundingBox = signatureFrame
            try! SignatureFormField.insertedSignatureField(withFullyQualifiedName: "dynamicallyAdded-\(i)", documentProvider: documentProvider, formElement: element)
        }
    }
}
