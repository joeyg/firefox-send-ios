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

    private let keychain: Keychain

    private let fileStore: FilesStore

    private let _progress = ReplaySubject<Float>.create(bufferSize: 1)

    public var progress: Observable<Float> {
        return _progress.asObservable()
    }

    private let baseUrl = "http://0.0.0.0:1443/api" // https://send.firefox.com/api/

    init(dispatcher: Dispatcher = Dispatcher.shared,
         fileStore: FilesStore = FilesStore.shared) {
        self.dispatcher = dispatcher
        self.fileStore = fileStore
        self.keychain = Keychain()

        self._progress.onNext(0.0)

        let navObservable = self.dispatcher.register
            .filterByType(class: FilesAction.self)

        Observable.combineLatest(navObservable, self.fileStore.files)
            .subscribe(onNext: { (action, files) in
                switch action {
                case FilesAction.send:
                    self.send(files)
                case FilesAction.sent(let owner, let id, let url, let nonce):
                    self.sent(owner: owner, id: id, url: url, nonce: nonce)
                default:
                    break
                }
            })
            .disposed(by: self.disposeBag)
    }

    private func sent(owner: String, id: String, url: String, nonce: String) {
        keychain.nonce = nonce
        let params: Parameters = [
            "owner_token": owner
        ]

        AF.request("\(baseUrl)/info/\(id)",
            method: .post,
            parameters: params,
            encoding: JSONEncoding.default)
            .responseJSON(completionHandler: { (response) in
                 debugPrint(response)
            })
    }

    private func send(_ files: [File]) {
        for file in files {
            do {
                let data = try Data(contentsOf: file.url)
                guard let encryptedFile = self.keychain.encryptFile(plaintext: data) else { continue }
                guard let metadata = self.keychain.encryptMetadata(name: file.name, type: file.type) else { continue }
                guard let authHeader = self.keychain.authKeyB64() else { continue }
                guard let rawSecret = self.keychain.toBase64(self.keychain.rawSecret) else { continue }
                let headers: HTTPHeaders = [
                    "X-File-Metadata": metadata,
                    "Authorization": "send-v1 \(authHeader)",
                ]

                AF.upload(multipartFormData: { multipartFormData in
                    multipartFormData.append(encryptedFile, withName: "data", mimeType: "application/octet-stream")
                },
                    to: "\(baseUrl)/upload",
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
                            guard let url = json.object(forKey: "url") as? String else { return }

                            debugPrint("\(url)#\(rawSecret)")

                            guard let newNonce = response.response?.httpHeaders["WWW-Authenticate"]?.split(separator: " ")[1] else {
                                return
                            }

                            if let ownerToken = json.object(forKey: "owner") as? String {
                                if let id = json.object(forKey: "id") as? String {

                                    self.dispatcher.dispatch(action: FilesAction.sent(owner: ownerToken, id: id, url: "\(url)#\(rawSecret)", nonce: String(newNonce)))

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
    }
}
