//
//  UpdaterMessages.swift
//  YikesStaffEngine
//
//  Created by Roger Mabillard on 2016-02-08.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

class CL_FirmwareUpdateRequest: Message, CustomStringConvertible {
    override class var identity : UInt8 { return 0x79 } // 121
    
    var messageID : UInt8?
    var messageVersion : UInt8?
    var initializationVector : [UInt8] = []
    var payload: [UInt8] = []
    
    var description: String {
        var desc = "Name: CL_FirmwareUpdateRequest"
        
        if let mid = messageID, let mvers = messageVersion {
                desc.appendContentsOf("\nID: \(String(format: "%02X", mid))")
                desc.appendContentsOf("\nMSG Vers: \(String(format: "%02X", mvers))")
                desc += "\n" + "IV: " + Message.bytesToHexString(initializationVector)
                desc += "\n" + "payload: " + Message.bytesToHexString(payload)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID                   <- map[start: 0, length: 1]
        messageVersion              <- map[start: 1, length: 1]
        initializationVector        <- map[start: 2, length: 16]
        payload                     <- map[toEndFrom: 18]
    }
}

class PL_FirmwareUpdateRequest : Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x7A } // 122
    
    var messageID : UInt8?
    var messageVersion : UInt8?
    var CL_firmwareUpdateRequest: [UInt8] = []
    
    var description: String {
        var desc = "Name: PL_FirmwareUpdateRequest"
        
        if let mid = messageID, let mvers = messageVersion {
            desc.appendContentsOf("\nID: \(String(format: "%02X", mid))")
            desc.appendContentsOf("\nBLE Interface Vers: \(String(format: "%02X", mvers)))")
            desc.appendContentsOf("\nCL Firm Req: \(Message.bytesToHexString(CL_firmwareUpdateRequest))")
        }
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID                   <- map[start: 0, length: 1]
        messageVersion              <- map[start: 1, length: 1]
        CL_firmwareUpdateRequest    <- map[toEndFrom: 2]
    }
}

class LP_StartFirmwareUpload: Message, CustomStringConvertible {
    override class var identity : UInt8 { return 0x7B } // 123
    
    var messageID :         UInt8?
    var messageVersion :    UInt8?
    var startingOffset :    UInt32 = 0
    
    var description: String {
        var desc = "Name: LP_StartFirmwareUpload"
        
        if let mid = messageID, let mvers = messageVersion {
                desc += "\n" + "ID: " + String(format: "%02X", mid)
                desc += "\n" + "Msg version: " + String(format: "%02X", mvers)
                desc += "\n" + "Starting offset: " + String(format: "%02X", startingOffset)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID           <- map[start: 0, length: 1]
        messageVersion      <- map[start: 1, length: 1]
        startingOffset      <- map[start: 2, length: 4]
    }
}

class PL_Firmware: Message, CustomStringConvertible {
    override class var identity : UInt8 { return 0x7C } // 124
    
    var messageID :             UInt8?
    var byteOffset :            UInt32 = 0
    var firmwarePacketSize :    UInt8?
    var firmwarePacket:         [UInt8] = []
    
    var description: String {
        var desc = "Name: PL_Firmware"
        
        if let mid = messageID, let fpsize = firmwarePacketSize {
                desc += "\n" + "ID: 0x" + String(format: "%02X", mid)
                desc += "\n" + "Byte Offset (decimal): " + String(format: "%u", byteOffset)
                desc += "\n" + "Firmware Packet Size (decimal): " + String(format: "%u", fpsize)
                desc += "\n" + "Firmware Packet: " + Message.bytesToHexString(firmwarePacket)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID                   <- map[start: 0, length: 1]
        byteOffset                  <- map[start: 1, length: 4]
        firmwarePacketSize          <- map[start: 5, length: 1]
        firmwarePacket              <- map[start: 6, length: Int(firmwarePacketSize!)]
    }
}

class PL_FirmwareUploadComplete: Message, CustomStringConvertible {
    override class var identity : UInt8 { return 0x7E } // 126
    
    var messageID :             UInt8?
    
    var description: String {
        var desc = "Name: PL_FirmwareUploadComplete"
        
        if let mid = messageID {
            desc += "\n" + "ID: " + String(format: "%02X", mid)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)        
        messageID                   <- map[start: 0, length: 1]
    }
}

class LP_Disconnect: Message, CustomStringConvertible {
    override class var identity : UInt8 { return 0x6B } // 107
    
    var messageID :             UInt8?
    var messageVersion :        UInt8?
    var disconnectReason :      UInt8?
    
    var description: String {
        var desc = "Name: LP_Disconnect"
        
        if let mid = messageID, let mvers = messageVersion,
            let dreason = disconnectReason {
                desc += "\n" + "ID: " + String(format: "%02X", mid)
                desc += "\n" + "Msg version: " + String(format: "%02X", mvers)
                desc += "\n" + "Disconnect Reason: " + String(format: "%02X", dreason)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID                   <- map[start: 0, length: 1]
        messageVersion              <- map[start: 1, length: 1]
        disconnectReason            <- map[start: 2, length: 1]
    }
}


class LC_FirmwareUpdateComplete: Message, CustomStringConvertible {
    override class var identity : UInt8 { return 0x7D } // 125
    
    var messageID :                 UInt8?
    var messageVersion :            UInt8?
    var initializationVector :      [UInt8] = []
    var payload:                    [UInt8] = []
    
    var description: String {
        var desc = "Name: LC_FirmwareUpdateComplete"
        
        if let mid = messageID, let mvers = messageVersion {
            desc += "\n" + "ID: " + String(format: "%02X", mid)
            desc += "\n" + "Msg version: " + String(format: "%02X", mvers)
            desc += "\n" + "IV: " + Message.bytesToHexString(initializationVector)
            desc += "\n" + "payload: " + Message.bytesToHexString(payload)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID                       <- map[start: 0, length: 1]
        messageVersion                  <- map[start: 1, length: 1]
        initializationVector            <- map[start: 2, length: 16]
        payload                         <- map[toEndFrom: 18]
    }
}


class PL_FirmwareUpdateCompleteAck: Message, CustomStringConvertible {
    override class var identity : UInt8 { return 0x7F } // 127
    
    var messageID : UInt8 = PL_FirmwareUpdateCompleteAck.identity
    
    var description: String {
        var desc = "Name: PL_FirmwareUpdateCompleAck"
        desc += "\n" + "ID: " + String(format: "%02X", messageID)
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        messageID                   <- map[start: 0, length: 1]
    }
}


class LC_TimeSyncRequest: Message, CustomStringConvertible {
    override class var identity: UInt8 { return 0x6C }  // 108
    
    var messageId:              UInt8?
    var messageVersion:         UInt8?
    var initializationVector:   [UInt8] = []
    var payload:                [UInt8] = []
    
    var description: String {
        var desc = "Name: LC_TimeSyncRequest"
        
        if let mid = messageId, let mvers = messageVersion {
            desc += "\n" + "ID: " + String(format: "%02X", mid)
            desc += "\n" + "Msg version: " + String(format: "%02X", mvers)
            desc += "\n" + "IV: " + Message.bytesToHexString(initializationVector)
            desc += "\n" + "Encrypted Payload: " + Message.bytesToHexString(payload)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageId                       <- map[start: 0, length: 1]
        messageVersion                  <- map[start: 1, length: 1]
        initializationVector            <- map[start: 2, length: 16]
        payload                         <- map[toEndFrom: 18]
    }
}

class CL_TimeSync : Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x6C }
    
    var messageID : UInt8?
    var messageVersion : UInt8?
    var initializationVector : [UInt8] = []
    var payload : [UInt8] = []
    
    var description: String {
        var desc = "Name: CL_TimeSync"
        if let mid = messageID, let mv = messageVersion {
            desc.appendContentsOf("\nID: \(String(format: "%02X", mid))")
            desc.appendContentsOf("\nMessageVersion: \(String(format: "%02X", mv))")
            desc.appendContentsOf("\nIV: \(Message.bytesToHexString(initializationVector))")
            desc.appendContentsOf("\nPayload: \(Message.bytesToHexString(payload))")
        }
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        messageVersion          <- map[start: 1, length: 1]
        initializationVector    <- map[start: 2, length: 16]
        payload                 <- map[toEndFrom: 18]
    }
    
}








class CL_RFIDControlDataUpdateRequest: Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x80 } // 128
    
    var messageID :             UInt8?
    var messageVersion :        UInt8?
    var initializationVector :  [UInt8] = []
    var payload :               [UInt8] = []
    
    var description: String {
        var desc = "Name: CL_RFIDControlDataUpdateRequest"
        
        if let mid = messageID, let mvers = messageVersion {
            desc += "\n" + "ID: " + String(format: "%02X", mid)
            desc += "\n" + "Msg version: " + String(format: "%02X", mvers)
            desc += "\n" + "IV: " + Message.bytesToHexString(initializationVector)
            desc += "\n" + "payload: " + Message.bytesToHexString(payload)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        messageVersion          <- map[start: 1, length: 1]
        initializationVector    <- map[start: 2, length: 16]
        payload                 <- map[toEndFrom: 18]
    }
}

class PL_CardKeyGroups: Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x82 } // 130
    
    var messageID :             UInt8?
    var packetSize :            UInt8?
    var data :                  [UInt8] = []
    
    var description: String {
        var desc = "Name: PL_CardKeyGroups"
        
        if let mid = messageID, let size = packetSize {
            desc += "\n" + "ID: " + String(format: "%02X", mid)
            desc += "\n" + "packetSize: " + String(format: "%02X", size)
            desc += "\n" + "data: " + Message.bytesToHexString(data)
        }
        
        return desc
    }
    
    static var maxPacketSize = 255
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        packetSize              <- map[start: 1, length: 1]
        data                    <- map[start: 2, length: Int(packetSize!)]
    }
}

class PL_CardKeyGroupsUploadComplete: Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x83 } // 131
    
    var messageID :             UInt8?
    
    var description: String {
        var desc = "Name: PL_CardKeyGroupsUploadComplete"
        
        if let mid = messageID {
            desc += "\n" + "ID: " + String(format: "%02X", mid)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
    }
}

class PL_CancelledStaffCards: Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x84 } // 132
    
    var messageID :             UInt8?
    var packetSize :            UInt8?
    var data :                  [UInt8] = []
    
    var description: String {
        var desc = "Name: PL_CancelledStaffCards"
        
        if let mid = messageID, let size = packetSize {
            desc += "\n" + "ID: " + String(format: "%02X", mid)
            desc += "\n" + "packetSize: " + String(format: "%02X", size)
            desc += "\n" + "data: " + Message.bytesToHexString(data)
        }
        
        return desc
    }
    
    static var maxPacketSize = 255
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        packetSize              <- map[start: 1, length: 1]
        data                    <- map[start: 2, length: Int(packetSize!)]
    }
}

class PL_CancelledStaffCardDataUploadComplete: Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x85 } // 133
    
    var messageID :             UInt8?
    
    var description: String {
        var desc = "Name: PL_CancelledStaffCardDataUploadComplete"
        
        if let mid = messageID {
            desc += "\n" + "ID: " + String(format: "%02X", mid)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
    }
}

class PL_RFIDControlDataUpdateCompleteAck: Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x87 } // 135
    
    var messageID :             UInt8?
    
    var description: String {
        var desc = "Name: PL_RFIDControlDataUpdateCompleteAck"
        
        if let mid = messageID {
            desc += "\n" + "ID: " + String(format: "%02X", mid)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
    }
}

class LP_Ack: Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x81 } // 129
    
    var messageID :             UInt8?
    
    var description: String {
        var desc = "Name: LP_Ack"
        
        if let mid = messageID {
            desc += "\n" + "ID: " + String(format: "%02X", mid)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
    }
}

class LC_RFIDControlDataUpdateComplete: Message, CustomStringConvertible {
    
    override class var identity : UInt8 { return 0x86 } // 134
    
    var messageID :             UInt8?
    var messageVersion :        UInt8?
    var initializationVector :  [UInt8] = []
    var payload :               [UInt8] = []
    
    var description: String {
        var desc = "Name: LC_RFIDControlDataUpdateComplete"
        
        if let mid = messageID, let mvers = messageVersion {
            desc += "\n" + "ID: " + String(format: "%02X", mid)
            desc += "\n" + "Msg version: " + String(format: "%02X", mvers)
            desc += "\n" + "IV: " + Message.bytesToHexString(initializationVector)
            desc += "\n" + "payload: " + Message.bytesToHexString(payload)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID               <- map[start: 0, length: 1]
        messageVersion          <- map[start: 1, length: 1]
        initializationVector    <- map[start: 2, length: 16]
        payload                 <- map[toEndFrom: 18]
    }
}


