//
//  DetailViewController.swift
//  Example
//
//  Created by Dat Ng on 6/10/19.
//  Copyright © 2019 datnm (laohac83x@gmail.com). All rights reserved.
//

import Foundation
import UIKit
import LHCoreRxRealmApiJWTExts
import RxCocoa
import RxSwift
import SwiftyJSON
import RealmSwift
import RxRealm

class RxDetailViewController: BaseViewController {
    let disposeBag = DisposeBag()
    var userId: Int64 = 0
    var userViewModel: SampleDetailViewModel?
    
    @IBOutlet weak var mImageView: UIImageView!
    @IBOutlet weak var mLabelFirstName: UILabel!
    @IBOutlet weak var mLabelLastName: UILabel!
    @IBOutlet weak var mLabelEmail: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userViewModel = SampleDetailViewModel(id: userId)
        self.bindData()
        userViewModel?.fetch()
    }
    
    func bindData() {
        userViewModel?.avatarString.subscribe(onNext: { [weak self] (avatar) in
            self?.mImageView.alamofireSetImage(avatar)
        }).disposed(by: disposeBag)
        
        userViewModel?.firstName.asDriver().drive(mLabelFirstName.rx.text).disposed(by: disposeBag)
        userViewModel?.lastName.asDriver().drive(mLabelLastName.rx.text).disposed(by: disposeBag)
        userViewModel?.email.asDriver().drive(mLabelEmail.rx.text).disposed(by: disposeBag)
    }
}
