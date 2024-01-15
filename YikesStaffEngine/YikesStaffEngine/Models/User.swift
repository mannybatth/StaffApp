//
//  User.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

public class User: Mappable, Hashable, CustomStringConvertible {
    
    public var userId: Int?
    public var firstName: String?
    public var lastName: String?
    public var email: String?
    public var middleInitial: String?
    public var phoneNumber: String?
    public var primaryPhone: Bool?
    public var deviceId: String?
    public var createdOn: NSDate?
    public var firstApiLoginOn: NSDate?
    
    public var roles: [Role]?
    
    public var beacon: Beacon?
    public var hotels: [Hotel]?
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        userId              <- map["id"]
        firstName           <- map["first_name"]
        lastName            <- map["last_name"]
        email               <- map["email"]
        middleInitial       <- map["middle_initial"]
        phoneNumber         <- map["phone_number"]
        primaryPhone        <- map["primary_phone"]
        deviceId            <- map["device_id"]
        createdOn           <- (map["created_on"], DateTimeTransform())
        firstApiLoginOn     <- (map["first_api_login_on"], DateTimeTransform())
        roles               <- map["roles"]
        hotels              <- map["hotels_data"]
        beacon              <- map["beacon_data"]
    }
    
    public var hashValue: Int {
        return userId!.hashValue
    }
    
    public var isYAdminMaster : Bool {
        
        guard let roles = roles else {
            return false
        }
        
        for role in roles {
            if role.name == "yAdmin_master" {
                return true
            }
        }
        
        return false
    }
    
    public var hasAuthorizationForOTA : Bool {
        
        guard let roles = roles else {
            return false
        }
        
        for role in roles {
            
            guard let resources = role.resources else {
                continue
            }
            
            for permission in resources {
                if permission.name == "ota_updates" {
                    return true
                }
            }
        }
        return false
    }
    
    public var description: String {
        if let jsonString = self.toJSONString(true) {
            return jsonString
        }
        return "{ userId: \(userId) }"
    }
}

public func == (lhs: User, rhs: User) -> Bool {
    return (lhs.userId == rhs.userId)
}
