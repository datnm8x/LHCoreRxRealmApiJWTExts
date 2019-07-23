//
//  LHCoreRxRealmListViewModel.swift
//  LHCoreRxRealmApiJWTExts iOS
//
//  Created by Dat Ng on 5/30/19.
//  Copyright © 2019 datnm (laohac83x@gmail.com). All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import RxSwift
import RealmSwift
import RxCocoa

// MARK: LHCoreRxRealmListViewModel ================================
open class LHCoreRxRealmListViewModel<T: Object> {
    public typealias TableCellBuilder = (_ item: T, _ tblView: UITableView, _ at: IndexPath) -> UITableViewCell?
    public typealias CollectionCellBuilder = (_ item: T, _ colView: UICollectionView, _ at: IndexPath) -> UICollectionViewCell?
    
    public typealias RxFetchFunction = (_ page: Int,_ per: Int) -> Observable<LHCoreListModel.ResultState<T>>
    public typealias RxSearchFunction = (_ keyword: String,_ page: Int,_ per: Int) -> Observable<LHCoreListModel.ResultState<T>>
    
    public let fetchFunction: RxFetchFunction
    public let searchFunction: RxSearchFunction?
    
    public let dataSource: LHCoreListViewDataSource<T> = LHCoreListViewDataSource<T>()
    internal var listType: LHCoreListModel.ViewType = .table
    open var layoutType: LHCoreListModel.LayoutType = .one_section {
        didSet {
            if layoutType != oldValue {
                self.reloadLayout()
            }
        }
    }
    
    internal var startPage: Int = LHCoreApiDefault.startPage
    internal var nextPage: Int = LHCoreApiDefault.startPage
    internal var pageSize: Int = LHCoreApiDefault.pageSize
    public let requestState = BehaviorRelay<LHCoreListModel.RequestState>(value: .none)
    public let didRequestHandler = BehaviorRelay<(LHCoreListModel.RequestType, LHCoreListModel.ResultState<T>)>(value: (.refresh, LHCoreListModel.ResultState<T>.successInitial))
    
    public let disposeBag: DisposeBag = DisposeBag()
    internal var disposeBagFetch: DisposeBag?
    internal let userScrollAction = BehaviorRelay<Bool>(value: false)
    internal var disposeBagAutoLoadMore: DisposeBag?
    internal weak var pListView: UIScrollView?
    
    internal var isSearchMode: Bool = false
    internal var searchKeyword: String = ""
    open var enableAutoLoadmore: Bool = true {
        didSet {
            if enableAutoLoadmore != oldValue {
                self.subcribeForAuToLoadMore()
            }
        }
    }
    public var isRequesting: Bool { return disposeBagFetch != nil && requestState.value != .none }
    internal var hasMoreData: Bool { return totalcount.value > resultCount }
    
    internal var resultsNotificationToken: NotificationToken?
    public let resultsChange = BehaviorRelay<RealmCollectionChange<Results<T>>?>(value: nil)
    internal var realmParams: (sortKey: String, ascending: Bool, filter: String?) = (sortKey: "id", ascending: true, filter: nil)
    internal var realmResults: Results<T>
    public var items: Results<T> { return realmResults }
    internal var resultCount: Int { return realmResults.count }
    public let totalcount: BehaviorRelay<Int> = BehaviorRelay<Int>(value: Int.max)
    
    public convenience init(fetchFunc: @escaping RxFetchFunction,
                     startPage: Int = LHCoreApiDefault.startPage, pageSize: Int = LHCoreApiDefault.pageSize,
                     sortKey: String = "id", ascending: Bool = true,
                     filter: String? = nil, searchFunc: RxSearchFunction? = nil,
                     cellBuilder: @escaping TableCellBuilder)
    {
        self.init(fetchFunc: fetchFunc, startPage: startPage, pageSize: pageSize,
                  sortKey: sortKey, ascending: ascending, filter: filter, searchFunc: searchFunc,
                  tableCellBuilder: cellBuilder, collectionCellBuilder: nil)
        self.listType = .table
    }
    
    public convenience init(fetchFunc: @escaping RxFetchFunction,
                     startPage: Int = LHCoreApiDefault.startPage, pageSize: Int = LHCoreApiDefault.pageSize,
                     sortKey: String = "id", ascending: Bool = true,
                     filter: String? = nil, searchFunc: RxSearchFunction? = nil,
                     collectionCellBuilder: @escaping CollectionCellBuilder)
    {
        self.init(fetchFunc: fetchFunc, startPage: startPage, pageSize: pageSize,
                  sortKey: sortKey, ascending: ascending, filter: filter, searchFunc: searchFunc,
                  tableCellBuilder: nil, collectionCellBuilder: collectionCellBuilder)
        self.listType = .collection
    }
    
    internal init(fetchFunc: @escaping RxFetchFunction, startPage: Int, pageSize: Int,
                  sortKey: String, ascending: Bool, filter: String?, searchFunc: RxSearchFunction?,
                  tableCellBuilder: TableCellBuilder?, collectionCellBuilder: CollectionCellBuilder?) {
        MainScheduler.ensureExecutingOnScheduler()
        
        self.realmParams.ascending = ascending
        self.realmParams.filter = filter
        self.realmParams.sortKey = sortKey
        
        self.startPage = startPage
        self.pageSize = pageSize
        self.fetchFunction = fetchFunc
        self.searchFunction = searchFunc
        
        do {
            let realm = try Realm()
            let rlmResult = String.lhprivateIsEmpty(realmParams.filter) ?
                realm.objects(T.self).sorted(byKeyPath: realmParams.sortKey, ascending: realmParams.ascending) :
                realm.objects(T.self).filter(realmParams.filter!).sorted(byKeyPath: realmParams.sortKey, ascending: realmParams.ascending)
            let countResult = rlmResult.count
            self.totalcount.accept(countResult)
            
            nextPage = Int(countResult / pageSize) + startPage
            self.realmResults = rlmResult
            // resultsNotification
            resultsNotificationToken = rlmResult.observe { [weak self] (rlmCollectionChange) in
                self?.resultsChange.accept(rlmCollectionChange)
            }
        } catch let error {
            fatalError(error.localizedDescription)
        }
        
        dataSource.tblCellBuilder = tableCellBuilder
        dataSource.colCellBuilder = collectionCellBuilder
        dataSource.delegate = self
    }
    
    public func bindDataSource(table: UITableView?) {
        guard let tblView = table, self.listType == .table else { return }
        
        self.pListView = tblView
        tblView.dataSource = self.dataSource
        tblView.reloadData()
        
        resultsChange.asDriver().drive(onNext: { (realmChange) in
            guard let realmChanged = realmChange else { return }
            switch realmChanged {
            case .initial(_):
                break
                
            case .update(_, let deletions, let insertions, let modifications):
                if deletions.count > 0 || insertions.count > 0 || modifications.count > 0 {
                    tblView.reloadData()
                }
                break
                
            case .error(_):
                break
            }
        }).disposed(by: disposeBag)
        
        self.subcribeForAuToLoadMore()
    }
    
    public func bindDataSource(collection: UICollectionView?) {
        guard let clView = collection, self.listType == .collection else { return }
        
        self.pListView = clView
        clView.dataSource = self.dataSource
        clView.reloadData()
        
        resultsChange.asDriver().drive(onNext: { (realmChange) in
            guard let realmChanged = realmChange else { return }
            switch realmChanged {
            case .initial(_):
                break
                
            case .update(_, let deletions, let insertions, let modifications):
                if deletions.count > 0 || insertions.count > 0 || modifications.count > 0 {
                    clView.reloadData()
                }
                break
                
            case .error(_):
                break
            }
        }).disposed(by: disposeBag)
        
        self.subcribeForAuToLoadMore()
    }
    
    internal func subcribeForAuToLoadMore() {
        self.disposeBagAutoLoadMore = nil
        guard let mListView = self.pListView, enableAutoLoadmore else { return }
        
        let pDisposeBag = DisposeBag()
        self.disposeBagAutoLoadMore = pDisposeBag
        
        mListView.rx.willBeginDragging.asObservable().subscribe(onNext: { [weak self] _ in
            self?.userScrollAction.accept(true)
        }).disposed(by: pDisposeBag)
        
        mListView.rx.didScrollToBottom.asObservable().subscribe(onNext: { [weak self] isScrollToBottom in
            guard let strongSelf = self, isScrollToBottom, strongSelf.isRequesting == false, strongSelf.userScrollAction.value, strongSelf.enableAutoLoadmore else { return }
            
            if strongSelf.hasMoreData {
                strongSelf.userScrollAction.accept(false)
                DispatchQueue.main.async {
                    strongSelf.fetchMoreData()
                }
            }
        }).disposed(by: pDisposeBag)
        
        mListView.rx.didEndDragging.asObservable().subscribe(onNext: { [weak self] decelerating in
            if !decelerating {
                self?.userScrollAction.accept(false)
            }
        }).disposed(by: pDisposeBag)
        
        mListView.rx.didEndDecelerating.asObservable().subscribe(onNext: { [weak self] _ in
            self?.userScrollAction.accept(false)
        }).disposed(by: pDisposeBag)
    }
    
    deinit {
        resultsNotificationToken?.invalidate()
    }
}

public extension LHCoreRxRealmListViewModel {
    func item(atIndex: Int?) -> T? {
        guard let mIndex = atIndex else { return nil }
        return mIndex >= realmResults.count ? nil : realmResults[mIndex]
    }
    
    func item(at: IndexPath?) -> T? {
        guard let indexPath = at else { return nil }
        var indexItem = indexPath.row
        if self.listType == .table {
            indexItem = self.layoutType == .one_section ? indexPath.row : indexPath.section
        } else {
            indexItem = self.layoutType == .one_section ? indexPath.item : indexPath.section
        }
        
        return self.item(atIndex: indexItem)
    }
    
    func deleteItem(atIndex: Int?) -> T? {
        if let object = self.item(atIndex: atIndex) {
            Realm.tryWrite({ (realm) in
                realm.delete(object)
            })
            let total_Count = self.totalcount.value - 1
            self.totalcount.accept((total_Count < 0) ? 0 : total_Count)
            return object
        } else {
            return nil
        }
    }
    
    func deleteItemId(_ itemId: Int64) -> T? {
        if let deleteItem = T.findById(id: itemId) {
            Realm.tryWrite({ (realm) in
                realm.delete(deleteItem)
            })
            let total_Count = self.totalcount.value - 1
            self.totalcount.accept((total_Count < 0) ? 0 : total_Count)
            return deleteItem
        } else {
            return nil
        }
    }
    
    func refreshData() {
        disposeBagFetch = nil
        if isSearchMode {
            doSearchingData(type: .refresh)
        } else {
            isSearchMode = false
            searchKeyword = ""
            doFetchData(type: .refresh)
        }
    }
    
    func fetchMoreData() {
        guard hasMoreData else { return }
        
        isSearchMode ? doSearchingData(type: .fetch) : doFetchData(type: .fetch)
    }
    
    func resetSearch() {
        self.isSearchMode = false
        self.refreshData()
    }
    
    func beginSearch(_ keyword: String) {
        self.searchKeyword = keyword //Save cache for loadmore
        self.isSearchMode = true
        self.refreshData()
    }
}

extension LHCoreRxRealmListViewModel {
    internal func reloadLayout() {
        doReloadListView()
    }
    
    internal func doReloadListView() {
        DispatchQueue.main.async { [weak self] in
            if let tblView = self?.pListView as? UITableView {
                tblView.reloadData()
            } else if let colView = self?.pListView as? UICollectionView {
                colView.reloadData()
            }
        }
    }
    
    internal func doFetchData(type: LHCoreListModel.RequestType = .fetch) {
        guard disposeBagFetch == nil else {
            self.didRequestHandler.accept((type, LHCoreListModel.ResultState<T>.error(NSError(domain: String(describing: self), code: LHCoreErrorCodes.hasRequesting, userInfo: nil))))
            return
        }
        
        let pDisposeBag = DisposeBag()
        disposeBagFetch = pDisposeBag
        let requestPage = type == .refresh ? self.startPage : self.nextPage
        self.requestState.accept(.requesting(type))
        
        fetchFunction(requestPage, pageSize)
            .subscribeOn(LHCoreRxAPIService.bkgScheduler)
            .map { [unowned self] result -> LHCoreListModel.ResultState<T> in
                switch result {
                case .success(let listResult):
                    Realm.tryWrite({ (realm) in
                        if type == .refresh {
                            let oldObjects = self.realmParams.filter == nil ?
                                realm.objects(T.self) :
                                realm.objects(T.self).filter(self.realmParams.filter!)
                            realm.delete(oldObjects)
                        }
                        realm.add(listResult.items, update: Realm.UpdatePolicy.all)
                    })
                    self.totalcount.accept(listResult.totalcount)
                    
                case .error(_):
                    break
                }
                
                return result
            }
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [unowned self] result in
                    MainScheduler.ensureExecutingOnScheduler()
                    
                    switch result {
                    case .success(_):
                        if type == .refresh { self.nextPage = self.startPage }
                        self.nextPage += 1
                        
                    case .error(let error):
                        #if DEBUG
                        print("\(self)->FetchData->error: ", error)
                        #endif
                    }
                    self.didRequestHandler.accept((type, result))
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {  [weak self] in
                        self?.requestState.accept(.none)
                        self?.disposeBagFetch = nil
                    }
                },
                onError: { [unowned self] error in
                    MainScheduler.ensureExecutingOnScheduler()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {  [weak self] in
                        self?.requestState.accept(.none)
                        self?.disposeBagFetch = nil
                    }
                    
                    self.didRequestHandler.accept((type, LHCoreListModel.ResultState<T>.error(error)))
            })
            .disposed(by: pDisposeBag)
    }
    
    internal func doSearchingData(type: LHCoreListModel.RequestType) {
        guard disposeBagFetch == nil else {
            self.didRequestHandler.accept((type, LHCoreListModel.ResultState<T>.error(NSError(domain: String(describing: self), code: LHCoreErrorCodes.hasRequesting, userInfo: nil))))
            return
        }
        
        let pDisposeBag = DisposeBag()
        disposeBagFetch = pDisposeBag
        
        let nextPage = type == .fetch ? self.nextPage : startPage
        requestState.accept(.requesting(type))
        
        self.searchFunction?(self.searchKeyword, nextPage, pageSize)
            .subscribeOn(LHCoreRxAPIService.bkgScheduler)
            .map { [unowned self] result -> LHCoreListModel.ResultState<T> in
                if !self.isSearchMode {
                    // user canceled searching already
                    throw NSError(domain: "\(self)", code: LHCoreErrorCodes.userCancel, userInfo: ["message": "User did cancelled"])
                }
                
                switch result {
                case .success(let listResult):
                    Realm.tryWrite({ (realm) in
                        if type == .refresh {
                            let results = self.realmParams.filter == nil ?
                                realm.objects(T.self) :
                                realm.objects(T.self).filter(self.realmParams.filter!)
                            realm.delete(results)
                        }
                        realm.add(listResult.items, update: Realm.UpdatePolicy.all)
                    })
                    self.totalcount.accept(listResult.totalcount)
                    
                default: break
                }
                
                return result
            }
            .observeOn(MainScheduler.instance)
            .subscribe(
                onNext: { [unowned self] result in
                    MainScheduler.ensureExecutingOnScheduler()
                    
                    switch result {
                    case .success(_):
                        if type == .refresh { self.nextPage = self.startPage }
                        self.nextPage += 1
                        #if DEBUG
                        print("\(self)->search->success")
                        #endif
                        
                    case .error(let error):
                        #if DEBUG
                        print("\(self)->SearchData->error: ", error)
                        #endif
                    }
                    self.didRequestHandler.accept((type, result))
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {  [weak self] in
                        self?.requestState.accept(.none)
                        self?.disposeBagFetch = nil
                    }
                },
                onError: { [unowned self] error in
                    MainScheduler.ensureExecutingOnScheduler()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {  [weak self] in
                        self?.requestState.accept(.none)
                        self?.disposeBagFetch = nil
                    }
                    
                    self.didRequestHandler.accept((type, LHCoreListModel.ResultState<T>.error(error)))
                        #if DEBUG
                    print("\(self)->SearchData->error: ", error)
                    #endif
            })
            .disposed(by: pDisposeBag)
    }
}

extension LHCoreRxRealmListViewModel: LHCoreListViewDataSourceProtocol {
    internal func numberOfSections() -> Int {
        return self.layoutType == .one_section ? 1 : self.resultCount
    }
    
    internal func numberOfRowsInSection(_ section: Int) -> Int {
        return self.layoutType == .one_section ? self.resultCount : 1
    }
    
    internal func itemForCell(at: IndexPath) -> Any? {
        return self.item(at: at)
    }
}

extension String {
    static func lhprivateIsEmpty(_ string: String?, trimCharacters: CharacterSet = CharacterSet(charactersIn: "")) -> Bool {
        guard let str = string?.trimmingCharacters(in: trimCharacters) else { return true }
        return str == ""
    }
}
