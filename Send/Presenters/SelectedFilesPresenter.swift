/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Alamofire

protocol SelectedFilesViewProtocol {
    func bind(items: Driver<[ItemSectionModel]>)
    func bindPickerValues(items: Observable<[String]>)
    var sendFilesButtonPressed: ControlEvent<Void> { get }
    func hideOptions()
}

class SelectedFilesPresenter {
    private var view: SelectedFilesViewProtocol
    private var dispatcher: Dispatcher
    private var filesStore: FilesStore
    private var uploadStore: UploadStore
    private let disposeBag = DisposeBag()

    init(view: SelectedFilesViewProtocol,
         dispatcher: Dispatcher = Dispatcher.shared,
         filesStore: FilesStore = FilesStore.shared,
         uploadStore: UploadStore = UploadStore.shared) {
        self.view = view
        self.dispatcher = dispatcher
        self.filesStore = filesStore
        self.uploadStore = uploadStore
    }

    func onViewReady() {
        let driver =
            Observable.combineLatest(self.filesStore.files, self.uploadStore.progress)
            .map { (arg) -> [ItemSectionModel] in

                let (files, progress) = arg
                return [ItemSectionModel(model: 0, items: self.configurationForFiles(files, progress: progress))]
            }
            .asDriver(onErrorJustReturn: [])

        self.view.bind(items: driver)

        self.view.bindPickerValues(items: Observable.just(["24 Hours", "12 Hours"]))

        self.view.sendFilesButtonPressed
            .subscribe(onNext: { (_) in
                self.dispatcher.dispatch(action: FilesAction.send)
                self.view.hideOptions()
            })
            .disposed(by: self.disposeBag)
    }

    private func configurationForFiles(_ files: [File], progress: Float) -> [FileCellConfiguration] {
        return files.map { (file) -> FileCellConfiguration in
            return FileCellConfiguration.Selected(name: file.name, size: self.fileSizeBytesToString(file.size), progress: progress)
        }
    }

    private func fileSizeBytesToString(_ bytes: UInt64) -> String {
        if bytes > 1000000000 {
            return "\(rounded(Double(bytes) / 1000000000, toPlaces: 2)) GB"
        } else if bytes > 1000000 {
            return "\(rounded(Double(bytes) / 1000000, toPlaces: 2)) MB"
        } else if bytes > 1000 {
            return "\(rounded(Double(bytes) / 1000, toPlaces: 2)) KB"
        }
        return "\(rounded(Double(bytes), toPlaces: 2)) B"
    }

    private func rounded(_ val: Double, toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (val * divisor).rounded() / divisor
    }
}
