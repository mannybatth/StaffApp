//
//  Constants.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

public enum APIEnv : String {
    
    case PROD
    case QA
    case DEV
    
    var baseURLString : String {
        switch self {
        case .DEV:
            return "https://dev-api.yikes.co"
        case .QA:
            return "https://qa-api.yikes.co"
        case .PROD:
            return "https://api.yikes.co"
        }
    }
    
    var cacheKey: String {
        switch self {
        case .DEV:
            return "current_user_DEV"
        case .QA:
            return "current_user_QA"
        case .PROD:
            return "current_user_PROD"
        }
    }
}

public enum ServiceType : String {
    
    case UnknownService
    case BluetoothService
    case LocationService
    case InternetConnectionService
    case PushNotificationService
    case BackgroundAppRefreshService
}

struct APIEnvironment {
    
    static let key = "current_api_environment_key"
    static var currentAPIEnvironment : APIEnv = .PROD {
        didSet {
            NSUserDefaults.standardUserDefaults().setObject(currentAPIEnvironment.rawValue, forKey: APIEnvironment.key)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
}


struct KeychainConstants {
    
    // keychain account names for storing username & password
    static let keychainAppServiceName = "com.yikesteam.staffapp"
    static let keychainEmailAccountName = "com.yikesteam.staffapp.email"
    static let keychainPasswordAccountName = "com.yikesteam.staffapp.password"
    
    // keychain account name for storing the session cookie
    static let keychainSessionTokenAccountName = "com.yikesteam.staffapp.session.token"
    
}

struct BLEConstants {
    
    static let yLinkServiceUUID = "C3221178-2E83-40E2-9F12-F07B57A77E1F"
    static let writeCharacteristicUUID = "06F87DA4-6264-4C8F-9ADB-D077380CEFA9"
    static let otaCharacteristicUUID = "70A65E35-262D-4E7B-A43D-0C30294DC727"
    
}


