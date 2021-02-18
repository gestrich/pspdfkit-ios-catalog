//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

private class CustomSignatureViewController: SignatureViewController {
    override func done(_ sender: Any?) {
        super.done(sender)
        print("point sequences: \(self.drawView.pointSequences)")
        print("pressure list: \(self.drawView.pressureList)")
        print("time points: \(self.drawView.timePoints)")
        print("touch radii: \(self.drawView.touchRadii)")
        print("input mode: \(self.drawView.inputMode)")

        let alert = UIAlertController(title: "Biometric Data", message: "See the console logs for the biometric data.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
        self.view.window?.rootViewController?.present(alert, animated: true)
    }
}

class AccessInkSignatureBiometricDataExample: Example {

    override init() {
        super.init()

        title = "Access Biometric Data for an Ink Signature"
        contentDescription = "Shows how to access the biometric data of an ink signature from the signature controller's draw view."
        category = .forms
        priority = 45
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let document = AssetLoader.writableDocument(withName: "Form_example.pdf", overrideIfExists: false)
        let controller = PDFViewController(document: document) {
            $0.overrideClass(SignatureViewController.self, with: CustomSignatureViewController.self)
        }
        return controller
    }
}
