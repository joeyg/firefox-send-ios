/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

class FilesStore {
    static let shared = FilesStore()
    private let disposeBag = DisposeBag()
    private let dispatcher: Dispatcher

    private let _files = ReplaySubject<[File]>.create(bufferSize: 1)

    public var files: Observable<[File]> {
        return _files.asObservable()
    }

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher

        self.dispatcher.register
            .filterByType(class: FilesAction.self)
            .subscribe(onNext: { (action) in
                switch action {
                case .selected(let files):
                    self._files.onNext(files)

                case .send:
                    self.files
                        .take(1)
                        .subscribe(onNext: { (files) in
                            let newFiles = files.map({ file -> File in
                                file.status = .uploading(progress: 0)
                                return file
                            })
                            self._files.onNext(newFiles)
                        })
                        .disposed(by: self.disposeBag)

                case .sent(let owner, let id, let url, let nonce):
                    self.files
                        .take(1)
                        .subscribe(onNext: { (files) in
                            let newFiles = files.map({ (file) -> File in
                                let newUrl = URL(string: url)
                                let file = File(status: .uploaded(shareUrl: newUrl), name: file.name, size: file.size, type: file.type, url: file.url)
                                file.shareUrl = newUrl
                                return file
                            })

                            self._files.onNext(newFiles)
                        })
                        .disposed(by: self.disposeBag)
                    break
                }
            })
            .disposed(by: self.disposeBag)
    }
}

class File {
    var status: FileStatus
    var name: String
    var size: UInt64
    var type: String
    var url: URL
    var shareUrl: URL?

    init(status: FileStatus,
         name: String,
         size: UInt64,
         type: String,
         url: URL) {
        self.status = status
        self.name = name
        self.size = size
        self.type = type
        self.url = url
    }
}

enum FileStatus {
    case selected
    case uploading(progress: Int)
    case uploaded(shareUrl: URL?)
}
