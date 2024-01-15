//
//  ControlDataOperation.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 5/10/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import CoreBluetooth

public class ControlDataOperation {
    
    public enum Status {
        case None
        case Scanning
        case Discovered
        case VerifyingUpdate
        case UpdateVerifyFailed
        case UpdateVerified
        case Connected
        case Updating
        case WriteComplete
        case UpdateFailed
        case UpToDate
        case UnknownDisconnect
    }
    
    public enum DisconnectReason: UInt8 {
        case INACTIVITY_TIMEOUT = 0x0C              // 12
        case RFID_CONTROL_DATA_SUPERSEDED = 0x0E    // 14
        case RFID_CONTROL_DATA_WRONG_SIZE
        case RFID_CONTROL_DATA_FAILED_CRC
        case UNSUPPORTED_MESSAGE_VERSION
    }
    
    public var ylink: YLink
    public var status : Status = .None
    public var controlDataUpdateProgress : CGFloat = 0
    public var lastDisconnectReason: DisconnectReason?
    public var latestRSSI: Int = 0
    
    weak var centralManager: CBCentralManager?
    var peripheral: CBPeripheral?
    var numOfSightingWithinThreshold: Int = 0
    var start: NSDate?
    var end: NSDate?
    
    var ackedUpdateRequest : Bool = false
    var ackedCardKeyGroups : Bool = false
    var ackedCancelledStaffCards : Bool = false
    
    var cardKeysGroupsOffset : Int = 0
    var cancelledStaffCardsOffset : Int = 0
    
    var wrotePL_CardKeyGroupsUploadComplete : Bool = false
    var wrotePL_CancelledStaffCardDataUploadComplete : Bool = false
    
    var lc_RFIDControlDataUpdateComplete : NSData?
    
    public var isInProgress : Bool {
        
        let statuses = [
            ControlDataOperation.Status.VerifyingUpdate,
            ControlDataOperation.Status.UpdateVerified,
            ControlDataOperation.Status.Connected,
            ControlDataOperation.Status.Updating,
            ControlDataOperation.Status.WriteComplete
        ]
        
        if statuses.contains(status) {
            return true
        }
        return false
    }
    
    /**
     Set this to `true` to do a manual update on a specific yLink as soon as it's discovered.
     */
    var userDidRequestControlDataUpdate: Bool = false
    
    /**
     Use this to check whether the user has tagged this yLink operation for manual update and if it still requires it.
     */
    internal func requiresManualUpdate() -> Bool {
        return self.end == nil && self.userDidRequestControlDataUpdate == true
    }
    
    public init(ylink: YLink) {
        self.ylink = ylink
    }
    
    func startOperation() {
        start = NSDate()
    }
    
    func endOperation() {
        end = NSDate()
        
        if let peripheral = peripheral {
            if peripheral.state == CBPeripheralState.Connected || peripheral.state == CBPeripheralState.Connecting {
                centralManager?.cancelPeripheralConnection(peripheral)
            }
        }
    }
    
    /**
     If an operation fails, call this to allow another try:
     */
    func restartOperation() {
        self.end = nil
        self.start = nil
        self.latestRSSI = 0
        self.ackedUpdateRequest = false
        self.ackedCardKeyGroups = false
        self.ackedCancelledStaffCards = false
        self.cardKeysGroupsOffset = 0
        self.cancelledStaffCardsOffset = 0
        self.wrotePL_CardKeyGroupsUploadComplete = false
        self.wrotePL_CancelledStaffCardDataUploadComplete = false
        self.lc_RFIDControlDataUpdateComplete = nil
    }
}

extension Array where Element:ControlDataOperation {
    
    func endAllOperations() {
        for operation in self {
            operation.endOperation()
        }
    }
    
    public func listOfRooms() -> [String] {
        var list : [String] = []
        for operation in self {
            if let roomNumber = operation.ylink.roomNumber {
                list.append(roomNumber)
            }
        }
        return list
    }
    
}
