//
//  Battery.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/31/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

class ISO8601ExtendedDateTransform: DateFormatterTransform {
    
    init() {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        super.init(dateFormatter: formatter)
    }
}

public enum BatteryStrength : String {
    case strong
    case ok
    case weak
    case danger
}

public class Battery: Mappable {
    
    public var strength : BatteryStrength?
    public var level: String?
    public var reportedOn: NSDate?
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        strength        <- (map["strength"], EnumTransform<BatteryStrength>())
        level           <- map["level"]
        reportedOn      <- (map["reported_on"], ISO8601ExtendedDateTransform())
    }
    
}
