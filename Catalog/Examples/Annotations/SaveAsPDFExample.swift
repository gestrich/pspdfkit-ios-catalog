//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

// This class will ask the user as soon as the first annotation has been added/modified where the annotation should be saved, and optionally copies the file to a new location.

class AnnotationSaveAsForAnnotationEditingExample: Example {
    override init() {
        super.init()
        title = "Save as... for annotation editing"
        contentDescription = "Adds an alert after detecting annotation writes to define a new save location."
        category = .annotations
        priority = 100
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let document = AssetLoader.writableDocument(withName: .JKHF, overrideIfExists: false)
        return SaveAsPDFViewController(document: document)
    }
}

// MARK: PDFViewController

private class SaveAsPDFViewController: PDFViewController {
     var hasUserBeenAskedAboutSaveLocation = false
     private var observer: Any?

    override func commonInit(with document: Document?, configuration: PDFConfiguration) {
        super.commonInit(with: document, configuration: configuration)

        navigationItem.rightBarButtonItems = [thumbnailsButtonItem, annotationButtonItem]

        let closeButton = UIBarButtonItem(image: SDK.imageNamed("x"), style: .done, target: self, action: #selector(closeButtonPressed(_:)))
        navigationItem.leftBarButtonItems = [closeButton]

        // PDFViewController will unregister all notifications on dealloc.
        observer = NotificationCenter.default.addObserver(forName: .PSPDFAnnotationChanged, object: nil, queue: OperationQueue.main) { notification in self.annotationChangedNotification(notification)
        }
        observer = NotificationCenter.default.addObserver(forName: .PSPDFAnnotationsAdded, object: nil, queue: OperationQueue.main) { notification in self.annotationAddedOrRemovedNotification(notification as NSNotification)
        }
        observer = NotificationCenter.default.addObserver(forName: .PSPDFAnnotationsRemoved, object: nil, queue: OperationQueue.main) { notification in self.annotationAddedOrRemovedNotification(notification as NSNotification)
        }
    }

    deinit {
    // Clear document cache, so we don't get annotation-artefacts when loading the doc again.
        SDK.shared.cache.remove(for: document)
    }

    // MARK: Private
    @objc func closeButtonPressed(_ sender: UIBarButtonItem) {
        annotationStateManager.state = nil  // Commit any annotations
        navigationController?.popViewController(animated: true)
    }

    func annotationChangedNotification(_ notification: Notification) {
        guard let notificationObject = notification.object as? Annotation else { return }
        processChangeForAnnotation(annotation: notificationObject)
    }

    func annotationAddedOrRemovedNotification(_ notification: NSNotification) {
        guard let notificationObject = notification.object as? [Annotation] else { return }
        for annotation in notificationObject {
            processChangeForAnnotation(annotation: annotation)
        }
    }

    func processChangeForAnnotation(annotation: Annotation) {
        if annotation.document == document {
            if Thread.isMainThread {
                self.askUserAboutSaveLocationIfNeeded()
            } else {
                DispatchQueue.main.async(execute: {
                    self.askUserAboutSaveLocationIfNeeded()
                })
            }
        }
    }

    // Mark - Document Copying Logic

    // This code assumes that the PDF location itself is writeable, and will fail for documents in the bundle folder.
    func askUserAboutSaveLocationIfNeeded() {
        // Make sure the alert gets displayed only once per session
        if hasUserBeenAskedAboutSaveLocation {
            return
        }
        hasUserBeenAskedAboutSaveLocation = true

        let alertController = UIAlertController(title: nil, message: "Would you like to save annotations into the current file, or create a copy to save the annotation changes?", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Save to This File", style: .destructive))
        alertController.addAction(UIAlertAction(title: "Save as Copy", style: .default, handler: { _ in
            self.replaceDocumentWithCopy()
        }))
        present(alertController, animated: true, completion: nil)
    }

    func replaceDocumentWithCopy() {
        guard let documentURL = document?.fileURL else { return }

        let newURL = adjustedFileURLForDocumentURL(documentURL)

        do {
            try FileManager.default.copyItem(at: documentURL, to: newURL)
            // Since the annotation has already been edited, we copy the file *before* it will be saved
            // then save the current state and switch out the documents.
        } catch {
            print("Failed to copy file to \(newURL.path): \(error.localizedDescription)")
            return
        }

        do {
            try document?.save()
        } catch {
            print("Failed to save document: \(error.localizedDescription)")
        }

        let tmpURL = newURL.appendingPathExtension("temp")
        do {
            try FileManager.default.moveItem(at: documentURL, to: tmpURL)
        } catch {
            print("Failed to move file: \(error.localizedDescription)")
            return
        }

        do {
            try FileManager.default.moveItem(at: newURL, to: documentURL)
        } catch {
            print("Failed to move file: \(error.localizedDescription)")
            return
        }

        do {
            try FileManager.default.moveItem(at: tmpURL, to: newURL)
        } catch {
            print("Failed to move file: \(error.localizedDescription)")
            return
        }

        // Finally update the fileURL, this will clear the current document cache.
        let newDocument = Document(url: newURL)
        newDocument.title = document?.title //preserve title

        // Preserve annotation selection
        guard var pageView: PDFPageView = pageViewForPage(at: pageIndex) else { return }
        guard let selectedAnnotations = pageView.selectedAnnotations else { return }

        document = newDocument

        // Restore selection
        pageView = pageViewForPage(at: pageIndex)!
        var newSelectedAnnotations: [Annotation] = []
        for annotation in newDocument.annotationsForPage(at: pageIndex, type: .all) {
            for selectedAnnotation in selectedAnnotations where annotation.name == selectedAnnotation.name {
                    newSelectedAnnotations.append(annotation)
            }
        }
        pageView.selectedAnnotations = newSelectedAnnotations

        // To re-show the popover, we need to wait until the alert view disappears.
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3, execute: {
            self.pageViewForPage(at: self.pageIndex)?.showMenuIfSelected(with: .allowPopovers, animated: false)
        })
    }

    /// Appends `_annotated` to the file basename. Also appends an incrementing integer if a file with a matching name already exists.
    ///
    /// For example, `Document.pdf` would change to `Document_annotated.pdf`.
    /// If `Document_annotated.pdf` already exists then `Document_annotated1.pdf` would be generated instead. Then `Document_annotated2.pdf` etc.
    private func adjustedFileURLForDocumentURL(_ documentURL: URL) -> URL {
        var appendFileCount = 0
        var newPath: NSString

        repeat {
            newPath = documentURL.path as NSString
            let appendSuffix = "_annotated\(appendFileCount == 0 ? "" : "\(appendFileCount)").pdf"
            if newPath.lowercased.hasSuffix(".pdf") {
                newPath = newPath.replacingOccurrences(of: ".pdf", with: appendSuffix, options: .caseInsensitive, range: NSRange(location: newPath.length - 4, length: 4)) as NSString
            } else {
                newPath = newPath.appending(appendSuffix) as NSString
            }
            appendFileCount += 1
        } while FileManager.default.fileExists(atPath: newPath as String)

        return NSURL.fileURL(withPath: newPath as String)
    }
}
