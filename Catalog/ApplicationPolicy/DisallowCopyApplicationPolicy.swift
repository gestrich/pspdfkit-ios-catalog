//
//  Copyright © 2016-2021 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import Foundation

class DisallowCopyApplicationPolicy: NSObject, ApplicationPolicy {

    // MARK: PSPDFApplicationPolicy
    func hasPermission(forEvent event: PolicyEvent, isUserAction: Bool) -> Bool {
        if event == .pasteboard {
            return false
        }
        return true
    }
}
