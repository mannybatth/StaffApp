//
//  Firmware.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

public class Firmware: Mappable, CustomStringConvertible {
    
    public var firmwareId : Int?
    public var version: Int?
    public var firmwareLoadedOn: NSDate?
    public var newFirmwareRequestedOn: NSDate?
    public var fileLocation: String?
    public var CL_FirmwareUpdateRequest: String?
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        firmwareId                  <- map["id"]
        version                     <- map["version"]
        firmwareLoadedOn            <- (map["firmware_loaded_on"], DateTimeTransform())
        newFirmwareRequestedOn      <- (map["new_firmware_requested_on"], DateTimeTransform())
        fileLocation                <- map["file_location"]
        CL_FirmwareUpdateRequest    <- map["cl_firmware_update_request"]
    }
    
    public var description: String {
        if let jsonString = self.toJSONString(true) {
            return jsonString
        }
        return "{ firmwareId: \(firmwareId) }"
    }
    
}
