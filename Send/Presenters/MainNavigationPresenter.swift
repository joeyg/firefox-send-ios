/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import RxSwift
import RxCocoa
import Alamofire

protocol MainNavigationViewProtocol {
    func pushView(_ vc: UIViewController)
    func popToRoot()
}

class MainNavigationPresenter {
    private var view: MainNavigationViewProtocol
    private var dispatcher: Dispatcher
    private let disposeBag = DisposeBag()

    init(view: MainNavigationViewProtocol,
         dispatcher: Dispatcher = Dispatcher.shared) {
        self.view = view
        self.dispatcher = dispatcher
    }

    func onViewReady() {
        self.dispatcher.register
            .filterByType(class: NavigationAction.self)
            .subscribe(onNext: { (action) in
                switch action {
                case .selectedFiles:
                    let vc = UIStoryboard(name: "SelectedFiles", bundle: nil).instantiateViewController(withIdentifier: "selectedfiles")
                    self.view.pushView(vc)
                }
            })
            .disposed(by: self.disposeBag)
    }
}
