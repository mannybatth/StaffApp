//
//  OTAOperation.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 3/8/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import CoreBluetooth

public class OTAOperation {
    
    public enum Status {
        case None
        case Scanning
        case Discovered
        case VerifyingUpdate
        case UpdateVerifyFailed
        case UpdateVerified
        case DownloadingFirmware
        case FirmwareDownloadFailed
        case FirmwareDownloadComplete
        case Connected              // Firmware downloaded & connected w/ ylink
        case Updating               // writing in progress (received a LP_StartFirmwareUpload)
        case FailedToWrite          // write failed (FIRMWARE_TOO_SMALL, FIRMWARE_TOO_BIG, FIRMWARE_FAILED_CRC, INACTIVITY_TIMEOUT)
        case WriteComplete          // write complete (FIRMWARE_UPLOAD_CONFIRMED)
        case ValidatingUpdate       // rebooted & waiting for confirmation from ylink
        case UpdateFailed           // received FIRMWARE_FAILED_TO_BOOT
        case UpToDate               // received LC_FirmwareUpdateComplete
        case UnknownDisconnect      // no LP_Disconnect was received before BLE disconnect
    }
    
    public enum DisconnectReason: UInt8 {
        case FIRMWARE_TOO_SMALL = 0x8
        case FIRMWARE_TOO_BIG
        case FIRMWARE_FAILED_CRC
        case FIRMWARE_UPLOAD_CONFIRMED
        case INACTIVITY_TIMEOUT
        case FIRMWARE_FAILED_TO_BOOT
    }
    
    public var ylink: YLink
    public var status : Status = .None
    public var OTAProgress : Float = 0
    public var lastDisconnectReason: DisconnectReason?
    public var latestRSSI: Int = 0
    
    public var writePL_FirmwareUploadCompleteDelay:Double = 1.0 // in seconds
    
    var otaTransferTimer: dispatch_source_t?
    var firmwareData : NSData?
    
    var transferStartDate: NSDate?
    var transferEndDate: NSDate? {
        didSet {
            if let newVersion = self.ylink.newFirmware?.version, let tt = self.transferTime() {
                let msg = String(format: "Wrote v%d in %.2fs", newVersion, tt)
                yOTALog(operation: self, message: msg)
            }
        }
    }
    public func transferTime () -> NSTimeInterval? {
        if let tsd = transferStartDate, ted = transferEndDate {
            let time = ted.timeIntervalSinceDate(tsd)
            return time
        }
        return nil
    }
    
    weak var centralManager: CBCentralManager?
    var peripheral: CBPeripheral?
    var numOfSightingWithinThreshold: Int = 0
    var offset: Int = 0
    var start: NSDate?
    var end: NSDate?
    
    var lp_startFirmwareUpload: LP_StartFirmwareUpload?
    var lc_FirmwareUpdateComplete: LC_FirmwareUpdateComplete?
    
    /**
     Set this to `true` to do a manual update on a specific yLink as soon as it's discovered.
     */
    var userDidRequestOTAUpdate: Bool = false
    
    public var isInProgress : Bool {
        
        let statuses = [
            OTAOperation.Status.VerifyingUpdate,
            OTAOperation.Status.UpdateVerified,
            OTAOperation.Status.DownloadingFirmware,
            OTAOperation.Status.FirmwareDownloadComplete,
            OTAOperation.Status.Connected,
            OTAOperation.Status.Updating,
            OTAOperation.Status.WriteComplete,
            OTAOperation.Status.ValidatingUpdate
        ]
        
        if statuses.contains(status) {
            return true
        }
        return false
    }
    
    /**
     Use this to check whether the user has tagged this yLink operation for manual update and if it still requires it.
     */
    internal func requiresManualUpdate() -> Bool {
        return self.end == nil && self.userDidRequestOTAUpdate == true
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
        self.OTAProgress = 0
    }
    
}

extension Array where Element:OTAOperation {
    
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
