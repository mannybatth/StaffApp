//
//  DateNoTimeTransform.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

class DateNoTimeTransform: TransformType {
    typealias Object = NSDate
    typealias JSON = String
    
    init() {}
    
    func transformFromJSON(value: AnyObject?) -> NSDate? {
        if let dateString = value as? String {
            return DateHelper.sharedInstance.simpleUTCDateFormatter.dateFromString(dateString)
        }
        return nil
    }
    
    func transformToJSON(value: NSDate?) -> String? {
        if let date = value {
            return DateHelper.sharedInstance.simpleUTCDateFormatter.stringFromDate(date)
        }
        return nil
    }
}
