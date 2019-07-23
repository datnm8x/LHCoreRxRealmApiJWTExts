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
    class func tryWrite(_ blockWrite: @escaping (_ realm: Realm) -> Void) -> Realm? {
        do {
            let realm = try Realm()
            do {
                try realm.write({
                    blockWrite(realm)
                })
            } catch { }
            return realm
        } catch {
            return nil
        }
    }
    
    class func write(_ block: @escaping (_ realm: Realm) -> Void) throws {
        do {
            let realm = try Realm()
            do {
                try realm.write({
                    block(realm)
                })
            } catch let error { throw error }
        } catch let error {
            throw error
        }
    }
    
    @discardableResult
    class func observableObject<T: Object>(_ type: T.Type, forId: Int64) -> RxSwift.Observable<([T], RxRealm.RealmChangeset?)> {
        let realm = try! Realm()
        let objects = realm.objects(type).filter("%K = %d", "id", forId)
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
    public static var schemaVersion: UInt64 = 1
    
    public static func setDefaultConfigurationMigration(_ migrationBlock: MigrationBlock? = nil) {
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: schemaVersion,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: migrationBlock)
        
        Realm.Configuration.defaultConfiguration = config
    }
}

public extension Object {
    class func findById(id: Int64) -> Self? {
        do {
            let realm = try Realm()
            return realm.object(ofType: self, forPrimaryKey: NSNumber(value: id))
        } catch { return nil }
    }
    
    class func findById(id: Int64, withRealm: Realm) -> Self? {
        return withRealm.object(ofType: self, forPrimaryKey: NSNumber(value: id))
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
