//
//  Copyright © 2020-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

/// The streaming document example can download documents on a page-by-page basis, so opening is pretty much instant.
/// This can be useful if you have a large document that you'd like to stream to the user in individual pages.
/// It requires that the document is split up into individual pages and accessible on your web server.
///
/// To test: Open a local webserver in the folder where the document can be found.
/// A simple way is via python, which is installed by default on macOS:
///
/// - python -m SimpleHTTPServer 8000    # Python 2
/// - python -m http.server              # Python 3
///
/// This example is a special case for fast display and comes with a few caveats:
/// - The document needs to be separated on a server
/// - Document outlines are not supported
/// - Document page labels are not supported
/// - Document Editor is not supported
/// - Digital Signatures are not supported
/// - Only the scrubber bar will update correctly
/// - Undo/Redo is not supported.
/// - The replaced document must have the same page count as the template part
/// - Only documents with a uniform page size are supported correctly. The document size is defined by the first page.
final class StreamingDocumentExample: Example {
    override init() {
        super.init()
        title = "Streaming a document on-demand from a web-server"
        self.contentDescription = "Demonstrates a way to load parts of a document on demand."
        category = .documentDataProvider
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController {
        let pagesPerChunk = 2
        // Load document and split into a temporary folder
        let documentURL = AssetLoader.document(withName: .quickStart).fileURL!
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        try? splitDocument(fileURL: documentURL, outputFolder: tempURL, chunkSize: pagesPerChunk)
        print("Open a webserver in \(tempURL.path) via python -m SimpleHTTPServer 8000")

        // Describe fetchable document and server location.
        // ** make sure to have a local webserver running or change URL **
        let pageCount = Document(url: documentURL, loadCheckpointIfAvailable: false).pageCount
        let chunks = FetchableDocument.chunks(pages: Int(pageCount), chunkSize: pagesPerChunk)
        let fetchableDocument = FetchableDocument(name: "PSPDFKit 10 QuickStart Guide.pdf",
                                                  url: URL(string: "http://localhost:8000")!,
                                                  chunks: chunks,
                                                  pageSize: CGSize(width: 768, height: 1024))

        // Build view controller.
        let document = fetchableDocument.buildDocument()
        document.isUndoEnabled = false
        let controller = PDFViewController(document: document) {
            $0.pageMode = .single
            // page labels will be confusing for split documents
            $0.isPageLabelEnabled = false
            // Use custom page view that shows download progress
            $0.overrideClass(PDFPageView.self, with: ProgressPageView.self)
        }

        let startDownload = {
            fetchableDocument.downloadAllFiles { chunkIndex, fileURL in
                guard let document = controller.document else { return }

                // As files are downloaded, we swap the data-based document provider with a file-based one.
                document.reload(documentProviders: [document.documentProviders[chunkIndex]]) { _ in
                    FileDataProvider(fileURL: fileURL)
                }
                // We also need to reload the UI to re-render the current page.
                // Operations touching UIKit must be done on the main thread.
                let pages = fetchableDocument.pagesFor(chunkIndex: chunkIndex)
                DispatchQueue.main.async {
                    controller.reloadPages(indexes: NSIndexSet(indexesIn: pages) as IndexSet, animated: true)
                }
            }
        }

        // Add menu on iOS 14 and newer (Example works on iOS 12 as well, just not advanced testing helpers)
        if #available(iOS 14.0, *) {
            let clearCacheItem = UIBarButtonItem(title: "Clear Cache", image: nil, primaryAction: UIAction(title: "Bla", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak controller] _ in

                try? FileManager.default.removeItem(at: fetchableDocument.downloadFolder)
                controller?.document = fetchableDocument.buildDocument()
                startDownload()

            }), menu: nil)
            controller.navigationItem.setLeftBarButtonItems([clearCacheItem], for: .document, animated: false)
            controller.navigationItem.leftItemsSupplementBackButton = true
        }

        startDownload()

        return controller
    }

    /// Simple internal helper to split document into individual files made up of `chunkSize` pages each.
    /// For a real project, you want to run this on your backend.
    private func splitDocument(fileURL: URL, outputFolder: URL, chunkSize: Int = 1) throws {
        let document = Document(url: fileURL, loadCheckpointIfAvailable: false)
        let fileName = fileURL.deletingPathExtension().lastPathComponent

        let chunks = FetchableDocument.chunks(pages: Int(document.pageCount), chunkSize: chunkSize)
        var startPage = 0
        for (chunkIndex, chunk) in chunks.enumerated() {
            guard let configuration = Processor.Configuration(document: document) else { return }
            configuration.includeOnlyIndexes(IndexSet(integersIn: Range(NSRange(location: startPage, length: chunk))!))
            let processor = Processor(configuration: configuration, securityOptions: nil)

            let outputURL = outputFolder.appendingPathComponent("\(fileName)_\(chunkIndex).pdf")
            // The processor doesn't overwrite files. Files might not yet exist on first run.
            do { try FileManager.default.removeItem(at: outputURL) } catch CocoaError.fileNoSuchFile { }
            try processor.write(toFileURL: outputURL)
            startPage += chunkSize
        }
        print("Split \(fileURL.path) into \(outputFolder.path).")
    }
}

/// Structure that defines all necessary information to dynamcally fetch documents, build, download and load them from cache.
private struct FetchableDocument: Codable {
    /// The name of the document (MyDocument.pdf)
    let name: String
    /// The remote URL of the document, where the individual chunks are accessible
    /// See buildDownloadURL for details.
    let url: URL
    /// The number of chunks. Each chunk corresponds to a number of pages.
    let chunks: [Int]
    /// Page size is uniform for simplicity.
    let pageSize: CGSize

    /// Helper to define where this document will be stored.
    /// The scheme is AppData/Documents/DocumentName
    var downloadFolder: URL {
        let documentFolderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentFolderURL.appendingPathComponent(name.replacingOccurrences(of: ".pdf", with: ""))
    }

    /// Calculate chunks for a specific page size
    static func chunks(pages: Int, chunkSize: Int = 1) -> [Int] {
        var pagesLeft = pages
        var chunks = [Int]()
        while pagesLeft > 0 {
            if pagesLeft >= chunkSize {
                chunks.append(chunkSize)
                pagesLeft -= chunkSize
            } else {
                chunks.append(pagesLeft)
                break
            }
        }
        return chunks
    }

    /// Build document backed by either files or temporary data.
    /// Accesses disk to check for exisiting chunks.
    func buildDocument() -> Document {
        var dataProviders = [DataProviding]()
        for index in chunks.indices {
            let url = buildDownloadURL(chunkIndex: index)
            let fileURL = localURLFrom(remoteUrl: url)
            // Check if we already have files on disk
            if FileManager.default.fileExists(atPath: fileURL.path) {
                dataProviders.append(FileDataProvider(fileURL: fileURL))
            } else {
                dataProviders.append(DataContainerProvider(data: blankPDFData(size: pageSize, pages: chunks[index])))
            }
        }
        return Document(dataProviders: dataProviders)
    }

    func pagesFor(chunkIndex: Int) -> NSRange {
        var startPage = 0
        for index in 0..<chunkIndex {
            startPage += chunks[index]
        }
        return NSRange(location: startPage, length: chunks[chunkIndex])
    }

    /// Helper that starts to download all files.
    func downloadAllFiles(updateHandler: @escaping ((_ chunkIndex: Int, _ fileURL: URL) -> Void)) {
        try? FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true, attributes: nil)

        // Start downloading all the pages. This could be made smarter to prioritize the current page.
        for index in chunks.indices {
            let url = buildDownloadURL(chunkIndex: index)
            fetchFile(url: url, targetFolderURL: downloadFolder) { downloadStatus in
                switch downloadStatus {
                case .success(let URL):
                    print("Downloaded: \(URL.lastPathComponent)")
                    updateHandler(index, URL)
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }

    /// Converts remote URL to local URL.
    private func localURLFrom(remoteUrl: URL) -> URL {
        downloadFolder.appendingPathComponent(remoteUrl.lastPathComponent)
    }

    /// Builds the download URL from the host, document name and chunk.
    private func buildDownloadURL(chunkIndex: Int) -> URL {
        let fileName = name.replacingOccurrences(of: ".pdf", with: "")
        let escapedName = "\(fileName)_\(chunkIndex).pdf".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        return URL(string: "\(url)/\(escapedName)")!
    }

    /// Simple async URL fetcher that returns a completion handler.
    private func fetchFile(url: URL, targetFolderURL: URL, completion: @escaping (_ fileURL: Result<URL, Error>) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { localURL, _, error in
            // Simulate slow connection!
            sleep(1)

            if let localURL = localURL {
                let targetURL = localURLFrom(remoteUrl: url)
                _ = try? FileManager.default.replaceItemAt(targetURL, withItemAt: localURL)
                completion(.success(targetURL))
            } else {
                completion(.failure(error!))
            }
        }
        task.resume()
    }

    /// Helper to create a blank white PDF with a specific size.
    private func blankPDFData(size: CGSize, pages: Int = 1) -> Data {
        UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: size.width, height: size.height),
                              format: UIGraphicsPDFRendererFormat())
            .pdfData {
                for _ in 0..<pages {
                    $0.beginPage()
                }
            }
    }
}

/// A page view subclass that can show a progress indicator centered to the page.
final class ProgressPageView: PDFPageView {
    /// Enable or disable displaying the progress view. Animates.
    var showProgressIndicator: Bool = false {
        didSet {
            guard showProgressIndicator != oldValue else { return }
            UIView.animate(withDuration: 0.3) {
                self.progressView.alpha = self.showProgressIndicator ? 1: 0
            }
        }
    }

    // Create and setup lazily
    lazy var progressView: UIActivityIndicatorView = {
        var progressView: UIActivityIndicatorView
        if #available(iOS 13, *) {
            progressView = UIActivityIndicatorView(style: .large)
        } else {
            progressView = UIActivityIndicatorView(style: .gray)
        }
        progressView.translatesAutoresizingMaskIntoConstraints = false
        annotationContainerView.addSubview(progressView)
        progressView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        progressView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        progressView.startAnimating()
        return progressView
    }()

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateProgressIndicator()
    }

    override func update() {
        super.update()
        updateProgressIndicator()
    }

    private func updateProgressIndicator() {
        // If the page is not backed by a file, it's still being loaded
        let documentProvider = presentationContext?.document?.documentProviderForPage(at: pageIndex)
        showProgressIndicator = documentProvider?.fileURL == nil
    }
}
