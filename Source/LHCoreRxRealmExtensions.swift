//
//  LHCoreRxRealmApiJWTExts.swift
//  LHCoreRxRealmApiJWTExts iOS
//
//  Created by Dat Ng on 6/5/19.
//  Copyright © 2019 datnm (laohac83x@gmail.com). All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift
import RxRealm

public extension Realm {
    class var tryInstance: Realm? {
        do {
            return try Realm()
        } catch { return nil }
    }
    
    @discardableResult
    class func tryWrite(realm: Realm? = nil, _ blockWrite: @escaping (_ realm: Realm) -> Void) -> Realm? {
        guard let realm = realm else {
            do {
                let mRealm = try Realm()
                do {
                    try mRealm.write({
                        blockWrite(mRealm)
                    })
                    return mRealm
                } catch {
                    return nil
                }
            } catch {
                return nil
            }
        }
        
        do {
            try realm.write({
                blockWrite(realm)
            })
            return realm
        } catch {
            return nil
        }
    }
    
    class func write(realm: Realm? = nil, _ block: @escaping (_ realm: Realm) -> Void) throws {
        if let realm = realm {
            do {
                try realm.write({
                    block(realm)
                })
            } catch let error { throw error }
        } else {
            do {
                let mRealm = try Realm()
                
                do {
                    try mRealm.write({
                        block(mRealm)
                    })
                } catch let error { throw error }
            } catch let error {
                throw error
            }
        }
    }
    
    class func add(_ obj: Object, update: UpdatePolicy = .error, moreWrite: ((_ realm: Realm) -> Void)? = nil) {
        self.tryWrite { (realm) in
            realm.add(obj, update: update)
            moreWrite?(realm)
        }
    }
    
    class func add<S: Sequence>(_ objects: S, update: UpdatePolicy = .error, moreWrite: ((_ realm: Realm) -> Void)? = nil) where S.Iterator.Element: Object {
        self.tryWrite { (realm) in
            realm.add(objects, update: update)
            moreWrite?(realm)
        }
    }
    
    @discardableResult
    class func observableObject<T: Object>(_ type: T.Type, forId: Int64) -> RxSwift.Observable<([T], RxRealm.RealmChangeset?)> {
        let realm = try! Realm()
        let objects = realm.objects(type).filter("%K = %d", "id", forId)
        return Observable.arrayWithChangeset(from: objects)
    }
    
    class func observableObject<T: Object>(_ type: T.Type, forIdString: String) -> RxSwift.Observable<([T], RxRealm.RealmChangeset?)> {
        let realm = try! Realm()
        let objects = realm.objects(type).filter("%K = %@", "id", forIdString)
        return Observable.arrayWithChangeset(from: objects)
    }
    
    @discardableResult
    class func observableObjects<T: Object>(_ type: T.Type, filter: String? = nil) -> RxSwift.Observable<([T], RxRealm.RealmChangeset?)> {
        let realm = try! Realm()
        let objects = filter == nil ? realm.objects(type) : realm.objects(type).filter(filter!)
        return Observable.arrayWithChangeset(from: objects)
    }
}

public final class LHCoreRealmConfig: NSObject {
    // you need increase this in the each relase, if you change realm models object db
    static var schemaVersion: UInt64 = 1
    
    public static func setDefaultConfigurationMigration(schemaVersion: UInt64? = nil, _ migrationBlock: MigrationBlock? = nil) {
        if let newSchemaVersion = schemaVersion {
            self.schemaVersion = newSchemaVersion
        }
        
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: self.schemaVersion,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: migrationBlock)
        
        Realm.Configuration.defaultConfiguration = config
    }
}

public extension Object {
    class func findById(_ id: Int64, realm: Realm? = nil) -> Self? {
        guard let realm = realm else {
            do {
                let realm = try Realm()
                return realm.object(ofType: self, forPrimaryKey: NSNumber(value: id))
            } catch { return nil }
        }
        
        return realm.object(ofType: self, forPrimaryKey: NSNumber(value: id))
    }
    
    class func findByPrimaryKey(_ primaryKey: String, realm: Realm? = nil) -> Self? {
        guard let realm = realm else {
            do {
                let realm = try Realm()
                return realm.object(ofType: self, forPrimaryKey: primaryKey)
            } catch { return nil }
        }
        
        return realm.object(ofType: self, forPrimaryKey: primaryKey)
    }
    
    static func deleteById(_ id: Int64, realm: Realm? = nil) {
        if let item = self.findById(id, realm: realm) {
            (realm ?? Realm.tryInstance)?.delete(item)
        }
    }
    
    static func deleteByPrimaryKey(_ primaryKey: String, realm: Realm? = nil) {
        if let item = self.findByPrimaryKey(primaryKey, realm: realm) {
            (realm ?? Realm.tryInstance)?.delete(item)
        }
    }
    
    func discardChanges() {
        self.realm?.cancelWrite()
    }
}

public extension Results {
    var array: [Element]? {
        return self.count > 0 ? self.map { $0 } : nil
    }
}
