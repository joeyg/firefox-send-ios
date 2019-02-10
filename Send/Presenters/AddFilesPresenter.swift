/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Alamofire

protocol AddFilesViewProtocol {
    var addFilesButtonPressed: ControlEvent<Void> { get }
    func showFilesDialog()
}

class AddFilesPresenter {
    private var view: AddFilesViewProtocol
    private var dispatcher: Dispatcher
    private var filesStore: FilesStore
    private let disposeBag = DisposeBag()

    init(view: AddFilesViewProtocol,
         dispatcher: Dispatcher = Dispatcher.shared,
         filesStore: FilesStore = FilesStore.shared) {
        self.view = view
        self.dispatcher = dispatcher
        self.filesStore = filesStore
    }

    func onViewReady() {
        self.view.addFilesButtonPressed
            .subscribe(onNext: { (_) in
                self.view.showFilesDialog()
            })
            .disposed(by: self.disposeBag)

        self.filesStore.files
            .subscribe(onNext: { (files) in

            })
            .disposed(by: self.disposeBag)
    }

    func filesSelected(urls: [URL]) {
        let files = urls.map { (url) -> File? in
            let fileString = url.absoluteString.replacingOccurrences(of: "file:/", with: "")
            if FileManager.default.isReadableFile(atPath: fileString) {
                do {
                    let attrs = try FileManager.default.attributesOfItem(atPath: fileString)
                    let size = attrs[FileAttributeKey.size] as! UInt64
                    let fileType = attrs[FileAttributeKey.type] as! String
                    let fileName = url.lastPathComponent
                    return File(status: FileStatus.selected,
                                name: fileName,
                                size: size,
                                type: fileType,
                                url: url)
                } catch let err {
                    print("File Error: \(err)")
                }
            } else {
                print("cant access file at \(url)")
            }

            url.stopAccessingSecurityScopedResource()
            return nil
        }

        let nonNilFiles = files.compactMap { $0 }

        self.dispatcher.dispatch(action: FilesAction.selected(files: nonNilFiles))
    }
}
