/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class Constant {
    struct color {
        static let viewBackgroundColor = UIColor.white
    }
    struct string {
        static let productName = NSLocalizedString("productName", value: "Firefox Send", comment: "Name of the product")
        static let landingHeader = NSLocalizedString("landing.header", value: "Private, Encrypted Sharing", comment: "Header at the top of the landing screen")
        static let landingSubheader = NSLocalizedString("landing.subheader", value: "from the makers of Firefox", comment: "Subheader at the top of the landing screen")
        static let startUploadFiles = NSLocalizedString("startUploadFiles", value: "Start upload files", comment: "Label to start upload files")
        static let anythingToSend = NSLocalizedString("anythingToSend", value: "Anything to send", comment: "label for anything to send")
    }
}
