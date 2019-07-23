//
//  LHCoreRxRealmDetailViewModel.swift
//  Example
//
//  Created by Dat Ng on 6/10/19.
//  Copyright © 2019 datnm (laohac83x@gmail.com). All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON
import RxCocoa
import RxSwift
import RxRealm

public struct LHCoreDetailModel {
    public enum State: Equatable {
        public static func == (lhs: LHCoreDetailModel.State, rhs: LHCoreDetailModel.State) -> Bool {
            switch (lhs, rhs) {
            case (.requesting, .requesting), (.ideal, .ideal):
                return true
            case (.error(let lError), .error(let rError)):
                return (lError as NSError).isEqual(rError as NSError)
            default:
                return false
            }
        }
        
        case requesting
        case ideal
        case error(Error)
    }
    
    public enum StateResult<T> {
        case ideal(T?)
        case requesting
    }
    
    public enum StateResultWithOptions<T, O> {
        case ideal(T, O?)
        case requesting
    }
}

public protocol LHCoreRxRealmFindItemById {
    associatedtype T: Object
    static func findItemById(id: Int64) -> Observable<LHCoreDetailModel.StateResult<T>>
    static func fetch(id: Int64) -> Observable<T>
}

public protocol LHCoreRxRealmFindItemByIdAndOptions {
    associatedtype Item: Object
    associatedtype Options: Any
    
    static func fetchWithOptions(id: Int64) -> Observable<(Item, Options?)>
}

open class LHCoreRxRealmDetailViewModel<T: LHCoreRxRealmFindItemById> {
    public let itemId: Int64
    fileprivate var mItem: T? = nil
    
    public let disposeBag = DisposeBag()
    public let state = BehaviorRelay<LHCoreDetailModel.State>(value: .ideal)
    public var indicatorViewHidden: Observable<Bool>?
    public var noDataFirstViewHidden: Observable<Bool>?
    public var retryViewHidden: Observable<Bool>?
    public var networkErrorBannerHidden: Observable<Bool>?
    
    //use to show message error on network state banner
    var currentError: NSError?
    public var item: T? { return self.mItem }
    
    public init(id: Int64) {
        assert(Thread.isMainThread)
        
        self.itemId = id
        
        indicatorViewHidden = state.asObservable().map { [unowned self] state -> Bool in
            switch state {
            case .requesting where self.item == nil: return false
            default: return true
            }}.distinctUntilChanged()
        
        noDataFirstViewHidden = state.asObservable().map { [unowned self] state -> Bool in
            switch state {
            case .ideal where self.item == nil: return false
            default: return true
            }}
            .distinctUntilChanged()
        
        retryViewHidden = state.asObservable().map { [unowned self] state -> Bool in
            switch state {
            case .error where self.item == nil : return false
            default: return true
            }
            }
            .distinctUntilChanged()
        
        networkErrorBannerHidden = state.asObservable().map { [unowned self] state -> Bool in
            if case .error = state, self.item != nil { return false } else { return true }
            }
            .distinctUntilChanged()
        
        Realm.observableObject(T.T.self, forId: self.itemId).subscribe(onNext: { [weak self] (objects, realmChangeset) in
            
            if realmChangeset != nil {
                // it's an update
                self?.mItem = objects.first as? T
            }
        }).disposed(by: self.disposeBag)
    }
    
    public func fetch(completion: ((NSError?) -> Void)? = nil) {
        assert(Thread.isMainThread)
        
        T.findItemById(id: itemId).subscribe(
            onNext: { [weak self] result in
                MainScheduler.ensureExecutingOnScheduler()
                
                switch result {
                case .requesting:
                    self?.state.accept(.requesting)
                case .ideal(let item):
                    self?.mItem = item as? T
                    self?.state.accept(.ideal)
                    completion?(nil)
                }
            },
            onError: { [weak self] mError in
                MainScheduler.ensureExecutingOnScheduler()
                
                let error = mError as NSError
                self?.currentError = error
                
                if error.isUnauthorizedError {
                    // UnAuthenticate error, logout ??
                    self?.mItem = nil
                    self?.state.accept(.error(error))
                } else {
                    self?.state.accept(.error(error))
                }
                completion?(error)
        })
            .disposed(by: self.disposeBag)
    }
    
    public func refresh(completion: ((NSError?) -> Void)? = nil) {
        if case .requesting = state.value {
            completion?(nil)
        } else {
            self.fetch(completion: completion)
        }
    }
    
    func resetError() {
        state.accept(.ideal)
    }
}

public extension LHCoreRxRealmFindItemById where Self: Object {
    static func findItemById(id: Int64) -> Observable<LHCoreDetailModel.StateResult<Self>> {
        return Observable.create({ (observable: AnyObserver<LHCoreDetailModel.StateResult<Self>>) -> Disposable in
            // Get Local data
            if let realm = Realm.tryInstance {
                if let item = realm.object(ofType: Self.self, forPrimaryKey: NSNumber(value: id)) {
                    assert(Thread.isMainThread)
                    observable.onNext(.ideal(item))
                }
                observable.onNext(.requesting)
            } else {
                observable.onNext(.requesting)
            }
            
            return fetch(id: id).observeOn(MainScheduler.instance).subscribe(
                onNext: { _ in
                    MainScheduler.ensureExecutingOnScheduler()
                    
                    do {
                        let realm = try Realm()
                        realm.refresh()
                        
                        if let item = realm.object(ofType: Self.self, forPrimaryKey: NSNumber(value: id)) {
                            observable.onNext(.ideal(item))
                            observable.onCompleted()
                        } else {
                            // FXIME: empty data, not found
                            observable.onNext(.ideal(nil))
                            observable.onCompleted()
                        }
                    } catch let error {
                        observable.onError(error)
                    }
            },
                onError: {
                    MainScheduler.ensureExecutingOnScheduler()
                    observable.onError($0)
            })
        })
    }
}
