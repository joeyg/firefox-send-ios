/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import Alamofire

class UploadStore {
    static let shared = UploadStore()
    private let disposeBag = DisposeBag()
    private let dispatcher: Dispatcher

    private let fileStore: FilesStore

    private let _progress = ReplaySubject<Float>.create(bufferSize: 1)

    public var progress: Observable<Float> {
        return _progress.asObservable()
    }

    init(dispatcher: Dispatcher = Dispatcher.shared,
         fileStore: FilesStore = FilesStore.shared) {
        self.dispatcher = dispatcher
        self.fileStore = fileStore

        self._progress.onNext(0.0)

        let navObservable = self.dispatcher.register
            .filterByType(class: FilesAction.self)

        Observable.combineLatest(navObservable, self.fileStore.files)
            .filter({ (action, files) -> Bool in
                switch action {
                case FilesAction.send:
                    return true
                default:
                    return false
                }
            })
            .subscribe(onNext: { (action, files) in
                for file in files {
                    do {
                        let data = try Data(contentsOf: file.url)
                        AF.upload(data, to: "https://send.firefox.com/api/upload")
                            .uploadProgress { progress in // main queue by default
                                let p = Float((progress.completedUnitCount / progress.totalUnitCount) * 100)
                                print(p)
                                self._progress.onNext(p)
                                print("Upload Progress: \(progress.fractionCompleted)")
                            }.responseString(completionHandler: { (response) in
                                self._progress.onNext(1.0)
                            debugPrint(response)
                        })
                    } catch let error {
                        debugPrint(error)
                    }
                }
            })
            .disposed(by: self.disposeBag)
    }
}
