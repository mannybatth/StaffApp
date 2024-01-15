//
//  RoleResource.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

public class RoleResource: Mappable {
    
    public var resourceId : Int?
    public var name: String?
    public var permission: String?
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        resourceId      <- map["id"]
        name            <- map["resource"]
        permission      <- map["permission"]
    }
    
}
