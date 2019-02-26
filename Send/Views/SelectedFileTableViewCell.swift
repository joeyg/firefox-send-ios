/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import RxSwift

class SelectedFileTableViewCell: UITableViewCell {
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var fileSizeLabel: UILabel!
    @IBOutlet weak var copyLinkbutton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!

    let disposeBag = DisposeBag()

    public func setText(name: String, size: String) {
        self.fileNameLabel.text = name
        self.fileSizeLabel.text = size
    }

    public func setProgress(_ progress: Float) {
        if progress > 0 {
            self.progressView.isHidden = false
            self.progressView.setProgress(progress, animated: true)
        } else {
            self.progressView.isHidden = true
        }
    }

    public func setShareUrl(_ url: URL) {
        self.copyLinkbutton.isHidden = false
    }
}
