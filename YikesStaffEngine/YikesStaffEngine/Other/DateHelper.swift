//
//  DateHelper.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

class DateHelper {
    
    static let sharedInstance = DateHelper()
    
    var calender : NSCalendar
    let simpleUTCDateFormatter = NSDateFormatter()
    let simpleUTCDateFormatterWithTime = NSDateFormatter()
    
    let simpleDateFormatterWithTime = NSDateFormatter()
    let simpleDateFormatterWithMilliSec = NSDateFormatter()
    let simpleDateFormatterWithTimeZone = NSDateFormatter()
    
    let dateFormatterWithMilliSec = NSDateFormatter()
    let minuteSecondMilliSecondFormatter = NSDateFormatter()
    let hourMinuteSecondFormatter = NSDateFormatter()
    
    init() {
        
        calender = NSCalendar.autoupdatingCurrentCalendar()
        
        simpleUTCDateFormatter.dateFormat = "yyyy-MM-dd"
        
        simpleUTCDateFormatterWithTime.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        simpleDateFormatterWithTime.dateFormat = "yyyy-MM-dd HH:mm:ss"
        simpleDateFormatterWithMilliSec.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        simpleDateFormatterWithTimeZone.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
        
        dateFormatterWithMilliSec.dateFormat = "MM-dd HH:mm:ss.SSS"
        minuteSecondMilliSecondFormatter.dateFormat = "mm:ss:SSS"
        hourMinuteSecondFormatter.dateFormat = "HH:mm:ss"
    }
    
    func daysBetweenDate(fromDateTime: NSDate?, toDateTime: NSDate?) -> Int {
        guard let from = fromDateTime, let to = toDateTime
        else { return 0 }
        
        var fromDate: NSDate?, toDate: NSDate?
        
        calender.rangeOfUnit(.Day, startDate: &fromDate, interval: nil, forDate: from)
        calender.rangeOfUnit(.Day, startDate: &toDate, interval: nil, forDate: to)
        
        let difference = calender.components(.Day, fromDate: fromDate!, toDate: toDate!, options: [])
        return difference.day
    }
    
    func isDate(date compareDate: NSDate, betweenDate earlierDate: NSDate, andDate laterDate: NSDate) -> Bool {
        
        if compareDate.compare(earlierDate) == .OrderedDescending {
            
            if compareDate.compare(laterDate) == .OrderedAscending {
                return true
            }
        }
        
        return false
    }
    
    func mergeTimeWithDate(date: NSDate, timeString: String, timezone: NSTimeZone? = NSTimeZone.localTimeZone()) -> NSDate? {
        
        let timeComps = timeString.componentsSeparatedByString(":")
        
        if timeComps.count >= 2 {
            
            let hourString = timeComps[0]
            let minuteString = timeComps[1]
            
            var dateComps = NSDateComponents()
            dateComps.timeZone = timezone
            dateComps = self.calender.components([.Year, .Month, .Day], fromDate: date)
            
            dateComps.hour = Int(hourString)!
            dateComps.minute = Int(minuteString)!
            
            let dateWithTime = self.calender.dateFromComponents(dateComps)
            return dateWithTime
        }
        
        return nil
    }
    
}
