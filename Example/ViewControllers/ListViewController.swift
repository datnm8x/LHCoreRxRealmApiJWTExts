//
//  ListViewController.swift
//  Example
//
//  Created by Dat Ng on 6/7/19.
//  Copyright © 2019 datnm (laohac83x@gmail.com). All rights reserved.
//

import Foundation
import UIKit
import LHCoreRxRealmApiJWTExts
import RxCocoa
import RxSwift
import SwiftyJSON

class ListViewController: BaseViewController {
    let disposeBag = DisposeBag()
    @IBOutlet weak var mTableView: BaseTableView!
    var listViewModel: LHCoreRxListViewModel<UserInfo>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mTableView.register(UserTableCell.nib, forCellReuseIdentifier: UserTableCell.reuseIdentifier)
        
        listViewModel = LHCoreRxListViewModel<UserInfo>(fetchFunc: ApiRequests.fetchUserInfos, cellBuilder: { (item, tableView, indexPath) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: UserTableCell.reuseIdentifier) as? UserTableCell
            cell?.setUserInfo(item)
            return cell
        })
        
        mTableView.delegate = self
        listViewModel?.bindDataSource(table: mTableView)
        mTableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            if let item = self?.listViewModel?.item(at: indexPath) {
                self?.gotoDetailViewController(id: item.id)
            }
        }).disposed(by: disposeBag)
        
        listViewModel?.refreshData()
    }
    
    func gotoDetailViewController(id: Int64) {
        if let detailVC = RxDetailViewController.instanceStoryboard(StoryboardsMgr.main) {
            detailVC.userId = id
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 308
    }
}
