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
                        let keychain = Keychain()
                        let data = try Data(contentsOf: file.url)
                        guard let encryptedFile = keychain.encryptFile(plaintext: data) else { continue }
                        guard let metadata = keychain.encryptMetadata(name: file.name, type: file.type) else { continue }
                        guard let authHeader = keychain.authKeyB64() else { continue }
                        guard let rawSecret = keychain.toBase64(keychain.rawSecret) else { continue }
                        let headers: HTTPHeaders = [
                            "X-File-Metadata": metadata,
                            "Authorization": "send-v1 \(authHeader)",
                        ]

                        AF.upload(multipartFormData: { multipartFormData in
                            multipartFormData.append(encryptedFile, withName: "data", mimeType: "application/octet-stream")
                            },
//                                  to: "https://send.firefox.com/api/upload",
                            to: "http://0.0.0.0:1443/api/upload",
                                  method: .post,
                                  headers: headers)
                            .uploadProgress { progress in // main queue by default
                                let p = Float((progress.completedUnitCount / progress.totalUnitCount) * 100)
                                print(p)
                                self._progress.onNext(p)
                                print("Upload Progress: \(progress.fractionCompleted)")

                            }.responseJSON(completionHandler: { (response) in
                                if let json = response.result.value as? NSDictionary {
                                    debugPrint(json)
                                    if let url = json.object(forKey: "url") as? String {
                                        debugPrint("\(url)#\(rawSecret)")
                                    }

                                    if let newNonce = response.response?.httpHeaders["WWW-Authenticate"]?.split(separator: " ")[1] {
                                        keychain.nonce = String(newNonce)
                                    }

                                    if let ownerToken = json.object(forKey: "owner") as? String {
                                        if let id = json.object(forKey: "id") as? String {
                                        let params: Parameters = [
                                            "owner_token": ownerToken
                                        ]

                                        AF.request("http://0.0.0.0:1443/api/info/\(id)",
                                                   method: .post,
                                                   parameters: params,
                                                   encoding: JSONEncoding.default)
                                            .responseJSON(completionHandler: { (response) in
                                               // debugPrint(response)
                                            })
                                        }
                                    }
                                }
                                debugPrint(response)
                                self._progress.onNext(1.0)

                        })
                    } catch let error {
                        debugPrint(error)
                    }
                }
            })
            .disposed(by: self.disposeBag)
    }
}
