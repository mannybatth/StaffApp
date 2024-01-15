//
//  AppManager.swift
//  StaffApp
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

class AppManager {
    
    class func isDEVTester(email: String) -> Bool {
        
        let trimmedEmail = email.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        if (trimmedEmail.caseInsensitiveCompare("alexandar.dimitrov@yikes.co") == NSComparisonResult.OrderedSame) {
            return true
        }
        
        if (trimmedEmail.caseInsensitiveCompare("manny.singh@yikes.co") == NSComparisonResult.OrderedSame) {
            return true
        }
        
        if (trimmedEmail.caseInsensitiveCompare("richardm@yikes.co") == NSComparisonResult.OrderedSame) {
            return true
        }
        
        if (trimmedEmail.caseInsensitiveCompare("roger.mabillard@yikes.co") == NSComparisonResult.OrderedSame) {
            return true
        }
        
        if (trimmedEmail.caseInsensitiveCompare("chad.coons@yikes.co") == NSComparisonResult.OrderedSame) {
            return true
        }
        
        if (trimmedEmail.caseInsensitiveCompare("ryan.pardieck@yikes.co") == NSComparisonResult.OrderedSame) {
            return true
        }
        
        if (trimmedEmail.caseInsensitiveCompare("hotel@yikes.co") == NSComparisonResult.OrderedSame) {
            return true
        }
        
        if (trimmedEmail.lowercaseString.hasSuffix("@yamm.ca")) {
            return true
        }
        
        return false
    }
    
    class func isQATester(email: String) -> Bool {
        
        let trimmedEmail = email.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        
        if (trimmedEmail.lowercaseString.hasSuffix("@yikes.co")) {
            return true
        }
        
        return false
    }
    
}
