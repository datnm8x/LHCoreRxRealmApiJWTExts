//
//  SampleFormViewModel.swift
//  Example
//
//  Created by Dat Ng on 6/6/19.
//  Copyright © 2019 datnm. All rights reserved.
//

import Foundation
import LHCoreRxRealmApiJWTExts
import RxCocoa
import RxSwift
import SwiftyJSON
import RealmSwift
import RxRealm

class SampleFormCellModel: LHCoreFormCellModel {
    // add your property here
    var title: String {
        return "Section: \(self.section)"
    }
    
    var subTitle: String {
        return "Row: \(self.row)"
    }
}

extension LHCoreListFormViewModel {
    // add your exten funcs here, example
    func doPostRegisterUserInfo() {
        
    }
}

// Example for declare sub class of LHCoreListFormViewModel
class SampleSubListFormViewModel<C: SampleFormCellModel, T: LHCoreFormViewModel<C>>: LHCoreListFormViewModel<C, T> {
    enum State: Equatable {
        case none
        case success
        case error(text: String)
    }
    var registerResult = BehaviorRelay<State>(value: .none)
    private let disposedBag = DisposeBag()
}

