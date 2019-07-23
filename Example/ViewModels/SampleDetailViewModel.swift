//
//  SampleDetailViewModel.swift
//  Example
//
//  Created by Dat Ng on 6/10/19.
//  Copyright © 2019 datnm (laohac83x@gmail.com). All rights reserved.
//

import Foundation
import LHCoreRxRealmApiJWTExts
import RxCocoa
import RxSwift
import SwiftyJSON
import RealmSwift
import RxRealm

class SampleDetailViewModel: LHCoreRxRealmDetailViewModel<UserDetailModel> {
    let firstName = BehaviorRelay<String?>(value: nil)
    let lastName = BehaviorRelay<String?>(value: nil)
    let email = BehaviorRelay<String?>(value: nil)
    let avatarString = BehaviorRelay<String?>(value: nil)
    
    override init(id: Int64) {
        super.init(id: id)
        
        state.asObservable().subscribe(onNext: { [weak self] (modelState) in
            self?.updateValues()
        }).disposed(by: disposeBag)
    }
    
    func updateValues() {
        firstName.accept(item?.first_name)
        lastName.accept(item?.last_name)
        email.accept(item?.email)
        avatarString.accept(item?.avatar)
    }
}

extension UserDetailModel: LHCoreRxRealmFindItemById {
    static func fetch(id: Int64) -> Observable<UserDetailModel> {
        return ApiRequests.fetchUser(id)
            .map({ json -> UserDetailModel in
                let user = UserDetailModel(json: json[ApiKeys.result])
                Realm.tryWrite({ (realm) in
                    realm.add(user, update: Realm.UpdatePolicy.all)
                })
                return user
            })
    }
}
