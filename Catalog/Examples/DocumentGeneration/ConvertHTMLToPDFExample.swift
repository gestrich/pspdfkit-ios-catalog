//
//  Copyright © 2018-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

//  MIT License (MIT) for Simple HTML invoice template: https://github.com/sparksuite/simple-html-invoice-template/blob/master/LICENSE

#if !targetEnvironment(macCatalyst)

class ConvertHTMLToPDFExample: Example {

    override init() {
        super.init()

        title = "Convert HTML to PDF"
        contentDescription = "Convert a URL containing simple HTML to PDF."
        category = .documentGeneration
        priority = 10
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let htmlFileURL = AssetLoader.assetURL(withName: "invoice.html")
        let htmlString = try! String(contentsOf: htmlFileURL, encoding: .utf8)
        let outputURL = TempFileURLWithPathExtension(prefix: "converted", pathExtension: "pdf")

        // start the conversion
        let status = StatusHUDItem.indeterminateProgress(withText: "Converting...")
        status.setHUDStyle(.black)
        status.push(animated: true, on: delegate.currentViewController?.view.window, completion: nil)

        let options = [PSPDFProcessorNumberOfPagesKey: 1, PSPDFProcessorDocumentTitleKey: "Generated PDF"] as [String: Any]
        Processor.generatePDF(fromHTMLString: htmlString, outputFileURL: outputURL, options: options) { actualOutputURL, error in
            if let error = error {
                // Update status to error.
                let statusError = StatusHUDItem.error(withText: error.localizedDescription)
                statusError.pushAndPop(withDelay: 2, animated: true, on: delegate.currentViewController?.view.window)
                status.pop(animated: true)
            } else if let actualOutputURL = actualOutputURL {
                // Update status to done.
                let statusDone = StatusHUDItem.success(withText: "Done")
                statusDone.pushAndPop(withDelay: 2, animated: true, on: delegate.currentViewController?.view.window)
                status.pop(animated: true)
                // Generate document and show it.
                let document = Document(url: actualOutputURL)
                let pdfController = PDFViewController(document: document)
                delegate.currentViewController!.navigationController?.pushViewController(pdfController, animated: true)
            }
        }
        return nil
    }
}

#endif
