//
//  TimeZoneTransform.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

class TimeZoneTransform: TransformType {
    typealias Object = NSTimeZone
    typealias JSON = String
    
    init() {}
    
    func transformFromJSON(value: AnyObject?) -> NSTimeZone? {
        if let timezoneString = value as? String {
            return NSTimeZone(name: timezoneString)
        }
        return nil
    }
    
    func transformToJSON(value: NSTimeZone?) -> String? {
        if let timezone = value {
            return timezone.name
        }
        return nil
    }
}