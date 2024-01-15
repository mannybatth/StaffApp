//
//  DateTimeTransform.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

class DateTimeTransform: TransformType {
    typealias Object = NSDate
    typealias JSON = String
    
    init() {}
    
    func transformFromJSON(value: AnyObject?) -> NSDate? {
        if let dateString = value as? String {
            return DateHelper.sharedInstance.simpleUTCDateFormatterWithTime.dateFromString(dateString)
        }
        return nil
    }
    
    func transformToJSON(value: NSDate?) -> String? {
        if let date = value {
            return DateHelper.sharedInstance.simpleUTCDateFormatterWithTime.stringFromDate(date)
        }
        return nil
    }
}
