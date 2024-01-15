//
//  YLink.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper
import CoreBluetooth

public class YLink: Mappable, Hashable, Equatable, CustomStringConvertible {
    
    public var yLinkId : Int?
    public var roomNumber: String?
    public var macAddress: String!
    
    // OTA
    public var firmware: Firmware?
    public var newFirmware: Firmware?
    
    // RFID
    public var CL_RFIDControlDataUpdateRequest: String?
    public var cardKeyGroups: String?
    public var cancelledStaffCards: String?
    
    // Reports
    public var yLinkBattery : Battery?
    public var lockBattery : Battery?
    
    public var writeCharacteristic: CBCharacteristic?
    public var otaCharacteristic: CBCharacteristic?
    
    public var uuid : CBUUID {
        return CBUUID(string: "A249B350-F112-E988-2015-\(macAddress)")
    }
    
    public init(macAddress: String) {
        self.macAddress = macAddress
    }
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        yLinkId                             <- map["id"]
        roomNumber                          <- map["room_number"]
        macAddress                          <- map["mac_address"]
        firmware                            <- map["firmware"]
        newFirmware                         <- map["new_firmware"]
        CL_RFIDControlDataUpdateRequest     <- map["cl_rfid_control_data_update_request"]
        cardKeyGroups                       <- map["card_key_groups"]
        cancelledStaffCards                 <- map["cancelled_staff_cards"]
        yLinkBattery                        <- map["ylink_battery"]
        lockBattery                         <- map["lock_battery"]
    }
    
    public var description: String {
        if let jsonString = self.toJSONString(true) {
            return jsonString
        }
        return "{ yLinkId: \(yLinkId) }"
    }
    
    public var hashValue: Int {
        return macAddress.hashValue
    }
}

public func == (lhs: YLink, rhs: YLink) -> Bool {
    return (lhs.macAddress == rhs.macAddress)
}

extension Array where Element:YLink {
    
    public func macAddresses() -> [String] {
        return map { $0.macAddress! }
    }
    
    public func uuids() -> [CBUUID] {
        return map { $0.uuid }
    }
    
    public func ylinksWithNewFirmware() -> [YLink] {
        return filter{ $0.newFirmware != nil }.map{ $0 }
    }
    
}

extension YLink {
    
    class func isYLinkAdvert(advUUID: CBUUID?) -> Bool {
        
        guard let advUUID = advUUID else {
            return false
        }
        
        return advUUID.UUIDString.hasPrefix("A249B350-F112-E988-2015")
    }
    
    class func macAddressFromAdvert(advUUID: CBUUID) -> String {
        
        return String(advUUID.UUIDString.characters.suffix(12))
    }
    
    class func advertsHaveNoReport(advManufacturerData: NSData?) -> Bool {
        
        guard let data = advManufacturerData else {
            return false
        }
        
        let bytesToFind : [UInt8] = [0x61, 0x01, 0x01]
        let dataToFind = NSData(bytes:bytesToFind, length: bytesToFind.count)
        
        let subdata = data[start: 0, length: 3]
        return subdata == dataToFind
    }
    
    class func advertsHaveReport(advManufacturerData: NSData?) -> Bool {
        
        guard let data = advManufacturerData else {
            return false
        }
        
        let bytesToFind : [UInt8] = [0x61, 0x01, 0x02]
        let dataToFind = NSData(bytes:bytesToFind, length: bytesToFind.count)
        
        let subdata = data[start: 0, length: 3]
        return subdata == dataToFind
    }
    
    class func advertsHaveKey(advManufacturerData: NSData?) -> Bool {
        
        guard let data = advManufacturerData else {
            return false
        }
        
        let bytesToFind : [UInt8] = [0x61, 0x01, 0x03]
        let dataToFind = NSData(bytes:bytesToFind, length: bytesToFind.count)
        
        let subdata = data[start: 0, length: 3]
        return subdata == dataToFind
    }
    
}
