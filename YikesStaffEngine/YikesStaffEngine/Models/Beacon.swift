//
//  Beacon.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

public class Beacon: Mappable {

    public var regionCount: Int?
    public var uuid: String?
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        regionCount     <- map["region_count"]
        uuid            <- map["uuid"]
    }
    
}
