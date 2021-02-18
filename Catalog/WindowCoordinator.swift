//
//  Copyright © 2019-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import UIKit

@objc(PSCWindowCoordinator)
class WindowCoordinator: NSObject {

    var window: UIWindow?

    var catalog: PSCCatalogViewController?
    @objc var catalogStack: UINavigationController?

    @discardableResult
    @objc(installCatalogStackInWindow:) func installCatalogStack(in window: UIWindow) -> PSCCatalogViewController {
        self.window = window

        var style: UITableView.Style = .grouped
        if #available(iOS 13, *) {
            style = .insetGrouped
        }

        let catalog = PSCCatalogViewController(style: style)
        let catalogStack = PDFNavigationController(rootViewController: catalog)
        catalogStack.navigationBar.prefersLargeTitles = true
        catalogStack.delegate = self

        catalog.window = window
        window.rootViewController = catalogStack
        window.makeKeyAndVisible()

        self.catalog = catalog
        self.catalogStack = catalogStack
        return catalog
    }

    @objc @discardableResult func handleOpenURL(_ url: URL?, options: [String: Any]? = nil) -> Bool {
        guard let url = url else { return false }
        // Directly open the PDF.
        if url.isFileURL {
            var fileURL = url
            // UIApplicationOpenURLOptionsOpenInPlaceKey is set NO when file is already copied to Documents/Inbox by iOS
            let openInPlace = options?[UIApplication.OpenURLOptionsKey.openInPlace.rawValue] as? NSNumber

            if openInPlace == nil || openInPlace?.boolValue == false {
                if IsFileLocatedInSamplesFolder(url) {
                    // Directly open if document is in Samples folder.
                    fileURL = url
                } else if IsFileLocatedInInbox(url) {
                    // Move to Documents if already present in Inbox, otherwise copy.
                    fileURL = MoveFileURLToDocumentFolder(url, override: true)
                } else {
                    if !url.startAccessingSecurityScopedResource(), FileManager.default.fileExists(atPath: url.path) {
                        return false
                    }
                    fileURL = CopyFileURLToDocumentFolder(url, override: true)
                    // Original URL needs to be used to revoke access.
                    url.stopAccessingSecurityScopedResource()
                }
            }

            presentViewControllerForDocument(at: fileURL)
            return true
        }
        return false
    }

    func presentViewControllerForDocument(at fileURL: URL) {
        let document = Document(url: fileURL)
        let pdfController = viewController(for: document)
        self.catalogStack?.popToRootViewController(animated: false)
        self.catalogStack?.pushViewController(pdfController, animated: false)
    }

    func viewController(for document: Document) -> PDFViewController {
        let pdfController = PDFViewController(document: document)
        pdfController.navigationItem.setRightBarButtonItems([pdfController.thumbnailsButtonItem, pdfController.annotationButtonItem, pdfController.outlineButtonItem, pdfController.searchButtonItem], for: .document, animated: false)
        return pdfController
    }

    func openTabbedControllerForDocument(at fileURL: URL) {
        let tabbedController = TabbedExampleViewController()
        tabbedController.documents = [Document(url: fileURL)]
        catalogStack?.popToRootViewController(animated: false)
        catalogStack?.pushViewController(tabbedController, animated: false)
    }

    @objc func openShortcutItem(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        print("Opening a shortcut item: \(shortcutItem)")

        self.catalogStack?.popToRootViewController(animated: false)
        guard let catalog = self.catalog else { return false }
        return catalog.openExample(withType: shortcutItem.type)
    }
}

extension WindowCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if viewController is PSCCatalogViewController {
            navigationController.navigationBar.prefersLargeTitles = true
        }
    }
}
