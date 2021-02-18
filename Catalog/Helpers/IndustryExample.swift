//
//  Copyright © 2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class IndustryExample: Example {
    /// An extended description showed by invoking moreInfoBarButtonItem.
    var extendedDescription: String?

    /// An optional URL with even more information shown on moreInfoBarButtonItem.
    var url: URL?

    /// The controller that should be used as the base for presenting the more info UI.
    private weak var presentedController: UIViewController?

    /// Shows extended information in a modal UI.
    lazy var moreInfoBarButtonItem: UIBarButtonItem = {
        let moreInfoButton = UIButton(type: .detailDisclosure)
        moreInfoButton.addTarget(self, action: #selector(didTapMoreInfoButton(_:)), for: .touchUpInside)
        return UIBarButtonItem(customView: moreInfoButton)
    }()

    @objc private func didTapMoreInfoButton(_ sender: UIButton) {
        showMoreInfoAlert()
    }

    private func showMoreInfoAlert() {
        guard let presentationContext = presentedController, let extendedDescription = extendedDescription else {
            return
        }

        let alertController = UIAlertController(title: self.title, message: extendedDescription, preferredStyle: .alert)
        if let url = url {
            let learnMoreAction = UIAlertAction(title: "Learn More...", style: .default, handler: { _ in
                UIApplication.shared.open(url)
            })
            alertController.addAction(learnMoreAction)
        }
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel))
        presentationContext.present(alertController, animated: true, completion: nil)
    }
}
