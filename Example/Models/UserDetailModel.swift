//
//  UserDetailModel.swift
//  Example
//
//  Created by Dat Ng on 6/11/19.
//  Copyright © 2019 datnm (laohac83x@gmail.com). All rights reserved.
//

import Foundation
import LHCoreRxRealmApiJWTExts
import RealmSwift
import RxSwift
import SwiftyJSON

class UserDetailModel: Object {
    @objc dynamic var id: Int64 = 0
    @objc dynamic var email: String?
    @objc dynamic var first_name: String?
    @objc dynamic var last_name: String?
    @objc dynamic var avatar: String?
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    required convenience init(json: JSON) {
        self.init()
        
        self.id = json[ApiKeys.id].int64Value
        self.email = json[ApiKeys.email].string
        self.first_name = json[ApiKeys.first_name].string
        self.last_name = json[ApiKeys.last_name].string
        self.avatar = json[ApiKeys.links][ApiKeys.avatar][ApiKeys.href].string
    }
}
