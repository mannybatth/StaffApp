//
//  EngineError.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

public struct EngineError {

    public static let Domain = "com.yikesteam.YikesStaffEngine"
    
    public enum Code: Int {
        case FailedToStartEngine        = -5000
        case MissingInputOutput         = -5001
        case ServerRequestFailed        = -5002
    }
    
    static func error(domain domain: String = EngineError.Domain, code: Code, failureReason: String) -> NSError {
        return error(domain: domain, code: code.rawValue, failureReason: failureReason)
    }
    
    static func error(domain domain: String = EngineError.Domain, code: Int, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: domain, code: code, userInfo: userInfo)
    }
    
}
