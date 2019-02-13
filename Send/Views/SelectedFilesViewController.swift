/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import RxCocoa
import RxSwift
import RxDataSources

typealias ItemSectionModel = AnimatableSectionModel<Int, FileCellConfiguration>

enum FileCellConfiguration {
    case Selected(name: String, size: String, progress: Float)
}

extension FileCellConfiguration: IdentifiableType {
    var identity: String {
        switch self {
        case .Selected(let name, _, _):
            return name
        }
    }
}

extension FileCellConfiguration: Equatable {
    static func ==(lhs: FileCellConfiguration, rhs: FileCellConfiguration) -> Bool {
        switch (lhs, rhs) {
        case (.Selected(let lhName, let lhSize, let lhProgress), .Selected(let rhName, let rhSize, let rhProgress)):
            return lhName == rhName && lhSize == rhSize && lhProgress == rhProgress
        }
    }
}

class SelectedFilesViewController: UIViewController {
    private var presenter: SelectedFilesPresenter?
    private var dataSource: RxTableViewSectionedAnimatedDataSource<ItemSectionModel>?
    private var disposeBag = DisposeBag()

    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var optionsView: UIView!
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = SelectedFilesPresenter(view: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableView.backgroundView = nil
        self.view.backgroundColor = Constant.color.filesScreenBackgroundColor
        self.tableView.backgroundColor = Constant.color.filesScreenBackgroundColor
        self.navigationItem.title = Constant.string.selectedFiles
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName: "SelectedFileTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "selectedfilecell")
        self.setupDataSource()
        self.presenter?.onViewReady()
    }

    private func setupDataSource() {
        self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        self.tableView.estimatedRowHeight = 100
        self.tableView.rowHeight = UITableView.automaticDimension
        self.dataSource = RxTableViewSectionedAnimatedDataSource<ItemSectionModel>(
            configureCell: { dataSource, tableView, path, _ in
                let cellConfiguration = dataSource[path]
                var retCell: UITableViewCell
                switch cellConfiguration {
                case .Selected(let name, let size, let progress):
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "selectedfilecell") as? SelectedFileTableViewCell else {
                            fatalError("Couldn't fild selected file table view cell")
                        }

                    cell.setText(name: name, size: size)
                    cell.setProgress(progress)

                    retCell = cell
                }

                return retCell
        })
    }
}

extension SelectedFilesViewController: SelectedFilesViewProtocol {
    func bind(items: Driver<[ItemSectionModel]>) {
        if let dataSource = self.dataSource {
            items.drive(self.tableView.rx.items(dataSource: dataSource)).disposed(by: self.disposeBag)
        }
    }

    func bindPickerValues(items: Observable<[String]>) {
        items.bind(to: self.pickerView.rx.itemTitles) { _, item in
            return item
        }
        .disposed(by: self.disposeBag)
    }

    public var sendFilesButtonPressed: ControlEvent<Void> {
        return self.sendButton.rx.tap
    }

    func hideOptions() {
        self.optionsView.isHidden = true
    }
}
