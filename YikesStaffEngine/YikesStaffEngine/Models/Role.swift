//
//  Role.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

public class Role: Mappable {
    
    public var roleId : Int?
    public var name: String?
    public var resources: [RoleResource]?
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        roleId          <- map["id"]
        name            <- map["name"]
        resources       <- map["resources"]
    }
    
}
