/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import RxCocoa
import RxSwift

class AddFilesViewController: UIViewController {
    private var presenter: AddFilesPresenter?

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addFilesButton: UIButton!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = AddFilesPresenter(view: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.view.backgroundColor = Constant.color.landingScreenBackgroundColor
        self.navigationItem.title = Constant.string.productName
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter?.onViewReady()
    }
}

extension AddFilesViewController: AddFilesViewProtocol {
    func showTableView() {
        self.contentView.isHidden = true
        self.tableView.isHidden = false
    }

    func showEmptyState() {
        self.tableView.isHidden = true
        self.contentView.isHidden = false
    }

    public var addFilesButtonPressed: ControlEvent<Void> {
        return self.addFilesButton.rx.tap
    }

    func showFilesDialog() {
        let vc = UIDocumentPickerViewController(documentTypes: ["public.data"], in: .import)
        vc.allowsMultipleSelection = true
        vc.delegate = self
        self.present(vc, animated: true, completion: nil)
    }
}

extension AddFilesViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.presenter?.filesSelected(urls: urls)
    }
}
