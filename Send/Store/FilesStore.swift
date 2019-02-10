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
    case uplaoded(link: URL)
}
