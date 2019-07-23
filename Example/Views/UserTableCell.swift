//
//  UserTableCell.swift
//  Example
//
//  Created by Dat Ng on 6/7/19.
//  Copyright © 2019 datnm (laohac83x@gmail.com). All rights reserved.
//

import Foundation
import LHCoreRxRealmApiJWTExts
import UIKit
import RxSwift
import RxRealm
import RxCocoa

class UserTableCell: UITableViewCell {
    @IBOutlet weak var mImageView: UIImageView!
    @IBOutlet weak var mLabelFirstName: UILabel!
    @IBOutlet weak var mLabelLastName: UILabel!
    @IBOutlet weak var mLabelEmail: UILabel!
    
    fileprivate var disposeBag: DisposeBag?
    
    var viewModel: UserTableCellViewModel? {
        didSet {
            guard let mViewModel = viewModel else {
                disposeBag = nil
                return
            }
            let mDisposeBag = DisposeBag()
            
            mViewModel.firstName.asDriver().drive(mLabelFirstName.rx.text).disposed(by: mDisposeBag)
            mViewModel.lastName.asDriver().drive(mLabelLastName.rx.text).disposed(by: mDisposeBag)
            mViewModel.email.asDriver().drive(mLabelEmail.rx.text).disposed(by: mDisposeBag)
            
            mViewModel.avatarString.asObservable().subscribe(onNext: { [weak self] (avatarString) in
                self?.mImageView.alamofireSetImage(avatarString)
            }).disposed(by: mDisposeBag)
            
            self.disposeBag = mDisposeBag
        }
    }
    
    func setUserModel(_ userModel: UserModel?) {
        if let user = userModel {
            self.viewModel = UserTableCellViewModel(user)
        } else {
            self.clearDatas()
        }
    }
    
    func clearDatas() {
        self.disposeBag = nil
        mLabelFirstName.text = nil
        mLabelLastName.text = nil
        mLabelEmail.text = nil
        mImageView.image = nil
    }
    
    func setUserInfo(_ userInfo: UserInfo?) {
        mImageView.alamofireSetImage(userInfo?.avatar)
        mLabelFirstName.text = userInfo?.first_name
        mLabelLastName.text = userInfo?.last_name
        mLabelEmail.text = userInfo?.email
    }
}

class UserTableCellViewModel {
    let user: UserModel
    fileprivate let disposeBag = DisposeBag()
    
    let firstName: BehaviorRelay<String?>
    let lastName: BehaviorRelay<String?>
    let email: BehaviorRelay<String?>
    let avatarString: BehaviorRelay<String?>
    
    init(_ user: UserModel) {
        MainScheduler.ensureExecutingOnScheduler()
        
        self.user = user
        self.firstName = BehaviorRelay<String?>(value: user.first_name)
        self.lastName = BehaviorRelay<String?>(value: user.last_name)
        self.email = BehaviorRelay<String?>(value: user.email)
        self.avatarString = BehaviorRelay<String?>(value: user.avatar)
    }
}
