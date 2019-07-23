//
//  MainViewController.swift
//  LHCoreRxRealmModels
//
//  Created by Dat Ng on 04/19/2019.
//  Copyright (c) 2019 datnm83@gmail.com. All rights reserved.
//

import UIKit
import LHCoreRxRealmApiJWTExts
import RxCocoa
import RxSwift
import SwiftyJSON
import RealmSwift
import RxRealm

class MainViewController: BaseViewController {
    let disposeBag = DisposeBag()
    @IBOutlet weak var mTableView: BaseTableView!
    
    var formViewModel: LHCoreListFormViewModel<SampleFormCellModel, LHCoreFormViewModel<SampleFormCellModel>>!
    var subFormViewModel: SampleSubListFormViewModel<SampleFormCellModel, LHCoreFormViewModel<SampleFormCellModel>>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mTableView.register(SampleTableCell.classForCoder(), forCellReuseIdentifier: SampleTableCell.reuseIdentifier)
        
        var datas = [LHCoreFormViewModel<SampleFormCellModel>]()
        for section in 0..<3 {
            let formView: LHCoreFormViewModel<SampleFormCellModel>  = LHCoreFormViewModel<SampleFormCellModel>()
            for row in 0..<10 {
                let fCell = SampleFormCellModel(section: section, row: row)
                formView.cells.append(fCell)
            }
            datas.append(formView)
        }
        
        formViewModel = LHCoreListFormViewModel<SampleFormCellModel, LHCoreFormViewModel<SampleFormCellModel>>(forms: datas, cellBuilder: { [weak self] (formCellModel, tableView, indexPath) -> UITableViewCell? in
            // return your config cells
            let cell = tableView.dequeueReusableCell(withIdentifier: SampleTableCell.reuseIdentifier)
            cell?.textLabel?.text = formCellModel.title
            cell?.detailTextLabel?.text = formCellModel.subTitle
            if indexPath.section == 1 {
                cell?.backgroundColor = UIColor.lightGray
            } else {
                cell?.backgroundColor = UIColor.white
            }
            
            return cell
        })
        
        formViewModel.bindDataSource(mTableView)
        DebugLog("bindDataSource..................", "mTableView")
        
        #if DEBUG
        // example without subclass of ListFormViewModel
        subFormViewModel = SampleSubListFormViewModel<SampleFormCellModel, LHCoreFormViewModel<SampleFormCellModel>>(forms: datas, cellBuilder: { [weak self] (formCellModel, tableView, indexPath) -> UITableViewCell? in
            // return your config cells
            return nil
        })
        #endif
        
        mTableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            print("\(indexPath.section) -> \(indexPath.row)")
            if let itemModel = self?.formViewModel?.item(atIndex: indexPath) {
                print(itemModel.title + "->" + itemModel.subTitle)
            }
            if indexPath.row % 2 == 0 {
                self?.gotoListViewController()
            } else {
                self?.gotoRxListViewController()
            }
        }).disposed(by: disposeBag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppearAtFirst(_ atFirst: Bool, animated: Bool) {
        super.viewWillAppearAtFirst(atFirst, animated: animated)
        DebugLog("bindDataSource..................")
        DebugLogFull("bindDataSource..................")
        DebugLogFull("bindDataSource..................", "mTableView")
    }
    
    override func viewDidAppearAtFirst(_ atFirst: Bool, animated: Bool) {
        super.viewDidAppearAtFirst(atFirst, animated: animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func gotoListViewController() {
        if let listVC = ListViewController.instanceStoryboard(StoryboardsMgr.main) {
            self.navigationController?.pushViewController(listVC, animated: true)
        }
    }
    
    func gotoRxListViewController() {
        if let listVC = RxListViewController.instanceStoryboard(StoryboardsMgr.main) {
            self.navigationController?.pushViewController(listVC, animated: true)
        }
    }
}
