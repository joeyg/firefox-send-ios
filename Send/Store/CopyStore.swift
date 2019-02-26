/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import RxSwift
import RxCocoa

class CopyStore {
    static let shared = CopyStore()
    private let disposeBag = DisposeBag()

    private let dispatcher: Dispatcher
    private let pasteboard: UIPasteboard
    private let _copyDisplay = PublishSubject<URL?>()

    public var copyDisplay: Driver<URL?> {
        return _copyDisplay.asDriver(onErrorJustReturn: nil)
    }

    init(dispatcher: Dispatcher = Dispatcher.shared,
         pasteboard: UIPasteboard = UIPasteboard.general) {
        self.dispatcher = dispatcher
        self.pasteboard = pasteboard

        self.dispatcher.register
            .filterByType(class: CopyAction.self)
            .bind { self.copy($0) }
            .disposed(by: self.disposeBag)
    }

    func copy(_ copyAction: CopyAction) {
        switch copyAction {
        case .copy(let url):
            let expireDate = Date().addingTimeInterval(TimeInterval(Constant.number.copyExpireTimeSecs))

            self.pasteboard.setItems([[UIPasteboard.typeAutomatic: url]],
                                     options: [UIPasteboard.OptionsKey.expirationDate: expireDate])
            self._copyDisplay.onNext(url)
        }

    }
}
