//
//  ClientInfoBuilder.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import Device

class ClientInfoBuilder {
    
    static let sharedInstance = ClientInfoBuilder()
    
    var clientVersionInfo : String {
        self.rebuildVersionInfo()
        
        var clientInfo : String = ""
        for (key, value) in info {
            clientInfo += "\(key):\(value);"
        }
        return clientInfo
    }
    
    var info : [String: String]!
    
    init() {
        
        info = [
            "os": "iOS",
            "osV": osVersion(),
            "StaffEngineV": engineVersion(),
            "StaffAppV": staffAppVersion(),
            "StaffAppB": staffAppBuild(),
            "model": phoneModel(),
        ]
    }
    
    func rebuildVersionInfo() {
        
        info["osV"] = osVersion()
        info["StaffEngineV"] = engineVersion()
        info["StaffAppV"] = staffAppVersion()
        info["StaffAppB"] = staffAppBuild()
    }
    
    func osVersion() -> String {
        return UIDevice.currentDevice().systemVersion
    }
    
    func engineVersion() -> String {
        guard let bundle = NSBundle(identifier: YikesStaffEngine.sharedEngine.bundleIdentifier),
            let infoDict = bundle.infoDictionary,
            let v = infoDict["CFBundleShortVersionString"] as? String,
            let b = infoDict["CFBundleVersion"] as? String
            else { return "" }
        
        return "\(v) b\(b)"
    }
    
    func staffAppVersion() -> String {
        guard let infoDict = NSBundle.mainBundle().infoDictionary,
              let version = infoDict["CFBundleShortVersionString"] as? String
            else { return "" }
        
        return version
    }
    
    func staffAppBuild() -> String {
        guard let build = NSBundle.mainBundle().objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String
            else { return "" }
        return build
    }
    
    func fullStaffAppVersion() -> String {
        var fullVersion = "\(staffAppVersion()) (\(staffAppBuild()))"
        #if DEBUG
            fullVersion += " d"
        #endif
        return fullVersion
    }
    
    func phoneModel() -> String {
        return Device.version().rawValue
    }
}
