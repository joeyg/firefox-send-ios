/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class Constant {
    struct color {
        static let landingScreenBackgroundColor = UIColor.white
        static let filesScreenBackgroundColor = UIColor(hex: 0xF3F8FE)
        static let fileCellBorderColor = UIColor(hex: 0xDDDDDD)
    }
    
    struct string {
        static let productName = NSLocalizedString("productName", value: "Firefox Send", comment: "Name of the product")
        static let landingHeader = NSLocalizedString("landing.header", value: "Private, Encrypted Sharing", comment: "Header at the top of the landing screen")
        static let landingSubheader = NSLocalizedString("landing.subheader", value: "from the makers of Firefox", comment: "Subheader at the top of the landing screen")
        static let startUploadFiles = NSLocalizedString("startUploadFiles", value: "Start upload files", comment: "Label to start upload files")
        static let anythingToSend = NSLocalizedString("anythingToSend", value: "Anything to send", comment: "label for anything to send")
        static let selectedFiles = NSLocalizedString("selectedFiles", value: "Selected Files", comment: "title for selected files screen")
        static let copyMessage = NSLocalizedString("copyMessage", value: "URL Copied", comment: "Label displayed to users after a copy action")
    }

    struct number {
       static let copyExpireTimeSecs = 60
    }
}
