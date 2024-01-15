//
//  ControlDataUpdateService.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/26/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import CoreBluetooth

public protocol ControlDataUpdateDelegate: class {
    func ControlDataUpdate(foundUpdatesForOperations operations: [ControlDataOperation])
    func ControlDataUpdate(startedScanningForYLinks operations: [ControlDataOperation])
    func ControlDataUpdate(RSSIUpdate RSSI:Int, operation: ControlDataOperation)
    func ControlDataUpdate(discoveredYLinkForOperation operation: ControlDataOperation)
    func ControlDataUpdate(verifyingOperation operation: ControlDataOperation)
    func ControlDataUpdate(operationVerifyFailed operation: ControlDataOperation)
    func ControlDataUpdate(operationVerifyPassed operation: ControlDataOperation)
    func ControlDataUpdate(didConnectWithYLink operation: ControlDataOperation)
    func ControlDataUpdate(didStartUpdate operation: ControlDataOperation)
    func ControlDataUpdate(updateWriteProgress operation: ControlDataOperation, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    func ControlDataUpdate(updateWriteComplete operation: ControlDataOperation)
    func ControlDataUpdate(controlDataUpToDate operation: ControlDataOperation)
    func ControlDataUpdate(controlDataUpdateFailed operation: ControlDataOperation)
    func ControlDataUpdate(didDisconnectFromYLink operation: ControlDataOperation)
    func ControlDataUpdate(operationRemovedFromScanList operation: ControlDataOperation)
}

class ControlDataUpdateService {
    
    weak var updater : YLinkUpdater?
    
    var operations : [ControlDataOperation] = []
    
    let minRSSIThreshold = -75
    let minThresholdSighting = 2
    let maximumConcurrentUpdates = 3
    
    let writeCharacteristicUUID = CBUUID(string: BLEConstants.writeCharacteristicUUID)
    
    init(updater: YLinkUpdater) {
        
        self.updater = updater
    }
    
    func restartAllOperations(forCentralManager centralManager: CBCentralManager) {
        
        defer {
            self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(foundUpdatesForOperations: operations)
            self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(startedScanningForYLinks: operations)
        }
        
        self.operations.endAllOperations()
        self.operations.removeAll()
        
        guard let ylinksWithControlDataUpdates = updater?.currentHotel.ylinksWithControlDataUpdates else {
            return
        }
        
        for ylink in ylinksWithControlDataUpdates {
            let operation = ControlDataOperation(ylink: ylink)
            operation.centralManager = centralManager
            self.operations.append(operation)
            
            operation.status = ControlDataOperation.Status.Scanning
        }
    }
    
    func removeOperationFromList(operation: ControlDataOperation) {
        
        self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(operationRemovedFromScanList: operation)
        
        defer {
            operation.endOperation()
            operations = operations.filter { $0 !== operation }
//            restartScan() TODO: Is this needed here?
        }
        
        guard let ylinks = self.updater?.currentHotel.ylinksWithControlDataUpdates else {
            return
        }
        
        self.updater?.currentHotel.ylinksWithControlDataUpdates = ylinks.filter { $0 !== operation.ylink }
    }
    
    func operationForYLinkUUID(UUIDToFind: CBUUID) -> ControlDataOperation? {
        
        for operation in operations {
            if operation.ylink.uuid == UUIDToFind {
                return operation
            }
        }
        return nil
    }
    
    func operationForPeripheral(peripheralToFind: CBPeripheral) -> ControlDataOperation? {
        
        for operation in operations {
            
            guard let peripheral = operation.peripheral else {
                continue
            }
            
            if peripheral == peripheralToFind {
                return operation
            }
        }
        return nil
    }
    
    func verifyUpdateIsNeeded(forOperation operation: ControlDataOperation) {
        
        yCDLog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): Verifying RFID update.")
        
        operation.status = ControlDataOperation.Status.VerifyingUpdate
        self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(verifyingOperation: operation)
        
        self.updater?.currentHotel.getYLinkControlDataUpdates(operation.ylink.yLinkId!, success: { ylink in
            
            guard let _ = ylink.CL_RFIDControlDataUpdateRequest else {
                
                operation.status = ControlDataOperation.Status.UpdateVerifyFailed
                self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(controlDataUpdateFailed: operation)
                
                yCDLog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "YLink doesn't have any control data headers, removing from list: \n\(ylink).")
                self.removeOperationFromList(operation)
                
                return
            }
            
            yCDLog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): RFID update verified from server.")
            
            operation.status = ControlDataOperation.Status.UpdateVerified
            self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(operationVerifyPassed: operation)
            
            operation.ylink = ylink
            
            if (self.updater?.updateMode == .Automatic || operation.requiresManualUpdate() == true) {
                self.startControlDataUpdate(forOperation: operation)
            }
            
        }) { error in
            
            operation.status = ControlDataOperation.Status.UpdateVerifyFailed
            self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(controlDataUpdateFailed: operation)
            
            yCDLog(LoggerLevel.Error, category: LoggerCategory.API, operation: operation, message: "Verify RFID update request for \(operation.ylink.roomNumber) failed: \(error)")
        }
    }
    
    func startControlDataUpdate(forOperation operation: ControlDataOperation) {
        
        yCDLog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): Starting Control Data update for room \(operation.ylink.roomNumber).")
        
        guard let peripheral = operation.peripheral else {
            
            yCDLog(LoggerLevel.Error, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): No peripheral found to connect with.")
            
            operation.status = ControlDataOperation.Status.Scanning
            self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(startedScanningForYLinks: [operation])
            
            self.updater?.restartScan()
            
            return
        }
        
        operation.startOperation()
        
        yCDLog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): Control data operation started at \(operation.start).")
        yCDLog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): Connecting with peripheral: \(peripheral).")
        
        operation.centralManager?.connectPeripheral(peripheral, options: nil)
    }
    
    func reportControlDataUpdateStatus(operation: ControlDataOperation, reason: ControlDataOperation.DisconnectReason) {
        
        self.updater?.currentHotel.updateYLinkRFIDStatusCode(Int(reason.rawValue), ylink: operation.ylink, success: {
            
            yCDLog(LoggerLevel.Debug, category: LoggerCategory.API, operation: operation, message: "Successfully sent control data update status: \(reason).")
            
        }) { error in
            
            yCDLog(LoggerLevel.Error, category: LoggerCategory.API, operation: operation, message: "Failed to send control data update status: \(reason). Error: \(error)")
        }
    }
    
    func reportLC_RFIDControlDataUpdateComplete(lc_RFIDControlDataUpdateComplete: String, operation: ControlDataOperation) {
        
        self.updater?.currentHotel.updateYLinkRFIDControlData(lc_RFIDControlDataUpdateComplete, ylink: operation.ylink, success: {
            
            yCDLog(LoggerLevel.Debug, category: LoggerCategory.API, operation: operation, message: "Successfully sent LC_RFIDControlDataUpdateComplete to yC.")
            
        }) { error in
            
            yCDLog(LoggerLevel.Error, category: LoggerCategory.API, operation: operation, message: "Failed to send LC_RFIDControlDataUpdateComplete to yC.")
        }
    }
    
    func numberOfActiveControlDataOperations() -> Int {
        
        var count = 0
        for operation in operations {
            if operation.isInProgress == true {
                count += 1
            }
        }
        return count
    }
}

// MARK: BLE Message indicates/reads
extension ControlDataUpdateService {
    
    func processIncomingMessage(rawData: NSData, operation: ControlDataOperation) {
        
        if LP_Ack.isThisMessageType(rawData) {
            handleLP_Ack(rawData, operation: operation)
            
        } else if LP_Disconnect.isThisMessageType(rawData) {
            handleLP_Disconnect(rawData, operation: operation)
            
        } else if LC_RFIDControlDataUpdateComplete.isThisMessageType(rawData) {
            handleLC_RFIDControlDataUpdateComplete(rawData, operation: operation)
        }
    }
    
    func handleLP_Ack(rawData: NSData, operation: ControlDataOperation) {
        
        yCDLog(operation: operation, message: "Identified incoming LP_Ack...")
        
        if operation.ackedUpdateRequest == false && operation.ackedCardKeyGroups == false {
            
            // ylink accepted CL_RFIDControlDataUpdateRequest
            
            operation.ackedUpdateRequest = true
            writeNextPL_CardKeyGroups(operation)
            
        } else if operation.ackedUpdateRequest == true && operation.ackedCardKeyGroups == false {
            
            // ylink accepted PL_CardKeyGroups
            
            operation.ackedCardKeyGroups = true
            writeNextPL_CancelledStaffCards(operation)
        }
    }
    
    func handleLP_Disconnect(rawData: NSData, operation: ControlDataOperation) {
        
        yCDLog(operation: operation, message: "Identified incoming LP_Disconnect...")
        
        guard let lp_disconnect = LP_Disconnect(rawData: rawData) else { return }
        
        if let disconnectReasonCode = lp_disconnect.disconnectReason {
            
            switch (disconnectReasonCode) {
                
            case ControlDataOperation.DisconnectReason.INACTIVITY_TIMEOUT.rawValue:
                operation.lastDisconnectReason = ControlDataOperation.DisconnectReason.INACTIVITY_TIMEOUT
                operation.end = NSDate()
                
                yCDLog(operation: operation, message: "Received an LP_Disconnect message \(ControlDataOperation.DisconnectReason.INACTIVITY_TIMEOUT)")
                
                operation.status = ControlDataOperation.Status.UpdateFailed
                self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(controlDataUpdateFailed: operation)
                
                reportControlDataUpdateStatus(operation, reason: ControlDataOperation.DisconnectReason.INACTIVITY_TIMEOUT)
                
                break
                
            case ControlDataOperation.DisconnectReason.RFID_CONTROL_DATA_SUPERSEDED.rawValue:
                operation.lastDisconnectReason = ControlDataOperation.DisconnectReason.RFID_CONTROL_DATA_SUPERSEDED
                operation.end = NSDate()
                
                yCDLog(operation: operation, message: "Received an LP_Disconnect message \(ControlDataOperation.DisconnectReason.RFID_CONTROL_DATA_SUPERSEDED)")
                
                operation.status = ControlDataOperation.Status.UpdateFailed
                self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(controlDataUpdateFailed: operation)
                
                reportControlDataUpdateStatus(operation, reason: ControlDataOperation.DisconnectReason.RFID_CONTROL_DATA_SUPERSEDED)
                
                break
                
            case ControlDataOperation.DisconnectReason.RFID_CONTROL_DATA_WRONG_SIZE.rawValue:
                operation.lastDisconnectReason = ControlDataOperation.DisconnectReason.RFID_CONTROL_DATA_WRONG_SIZE
                operation.end = NSDate()
                
                yCDLog(operation: operation, message: "Received an LP_Disconnect message \(ControlDataOperation.DisconnectReason.RFID_CONTROL_DATA_WRONG_SIZE)")
                
                operation.status = ControlDataOperation.Status.UpdateFailed
                self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(controlDataUpdateFailed: operation)
                
                reportControlDataUpdateStatus(operation, reason: ControlDataOperation.DisconnectReason.RFID_CONTROL_DATA_WRONG_SIZE)
                
                break
                
            case ControlDataOperation.DisconnectReason.RFID_CONTROL_DATA_FAILED_CRC.rawValue:
                operation.lastDisconnectReason = ControlDataOperation.DisconnectReason.RFID_CONTROL_DATA_FAILED_CRC
                operation.end = NSDate()
                
                yCDLog(operation: operation, message: "Received an LP_Disconnect message \(ControlDataOperation.DisconnectReason.RFID_CONTROL_DATA_FAILED_CRC)")
                
                operation.status = ControlDataOperation.Status.UpdateFailed
                self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(controlDataUpdateFailed: operation)
                
                reportControlDataUpdateStatus(operation, reason: ControlDataOperation.DisconnectReason.RFID_CONTROL_DATA_FAILED_CRC)
                
                break
                
            case ControlDataOperation.DisconnectReason.UNSUPPORTED_MESSAGE_VERSION.rawValue:
                operation.lastDisconnectReason = ControlDataOperation.DisconnectReason.UNSUPPORTED_MESSAGE_VERSION
                operation.end = NSDate()
                
                yCDLog(operation: operation, message: "Received an LP_Disconnect message \(ControlDataOperation.DisconnectReason.UNSUPPORTED_MESSAGE_VERSION)")
                
                operation.status = ControlDataOperation.Status.UpdateFailed
                self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(controlDataUpdateFailed: operation)
                
                reportControlDataUpdateStatus(operation, reason: ControlDataOperation.DisconnectReason.UNSUPPORTED_MESSAGE_VERSION)
                
                break
                
            default:
                yCDLog(operation: operation, message: "Disconnect reason code not handled (yet): \(disconnectReasonCode)")
            }
            
        }
    }
    
    func handleLC_RFIDControlDataUpdateComplete(rawData: NSData, operation: ControlDataOperation) {
        
        operation.ackedCancelledStaffCards = true
        
        if operation.lc_RFIDControlDataUpdateComplete == nil {
            
            operation.lc_RFIDControlDataUpdateComplete = rawData
            
            yCDLog(operation: operation, message: "Detected incoming LC_RFIDControlDataUpdateComplete -> Sending a read request.")
            
            if let peripheral = operation.peripheral, let writeCharacteristic = operation.ylink.writeCharacteristic {
                peripheral.readValueForCharacteristic(writeCharacteristic)
            }
            else {
                yCDLog(.Warning, category:.BLE, operation: operation, message:"LC_RFIDControlDataUpdateComplete - Missing peripheral reference to readValueForCharacteristic for room: \(operation.ylink.roomNumber)")
            }
            
        } else {
            
            let dataHexString = rawData.hexadecimalString()
            
            operation.end = NSDate()
            
            yCDLog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "Received full LC_RFIDControlDataUpdateComplete message:\n\(dataHexString)")
            
            if let start = operation.start, end = operation.end {
                yCDLog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "Time to update: \(String(format: "%.2fs", end.timeIntervalSinceDate(start))))")
            }
            
            writePL_RFIDControlDataUpdateCompleteAck(operation)
            
            operation.status = ControlDataOperation.Status.UpToDate
            self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(controlDataUpToDate: operation)
            
            reportLC_RFIDControlDataUpdateComplete(dataHexString, operation: operation)
            
            operation.lc_RFIDControlDataUpdateComplete = nil
            
            
            // remove operation
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3.0 * Double(NSEC_PER_SEC))), self.updater!.queue) {
                self.removeOperationFromList(operation)
            }
        }
    }
    
    func handleIncomingWriteConfirmation(rawData: NSData?, operation: ControlDataOperation) {
        
        if operation.ackedUpdateRequest == true && operation.ackedCardKeyGroups == false && operation.ackedCancelledStaffCards == false {
            
            if operation.wrotePL_CardKeyGroupsUploadComplete == false {
                
                // continue to write next groups
                writeNextPL_CardKeyGroups(operation)
            }
            
        } else if operation.ackedUpdateRequest == true && operation.ackedCardKeyGroups == true && operation.ackedCancelledStaffCards == false {
            
            if operation.wrotePL_CancelledStaffCardDataUploadComplete == false {
                
                // continue to write next cancelled staff cards
                writeNextPL_CancelledStaffCards(operation)
            }
        }
    }
    
}

// MARK: BLE Message writes
extension ControlDataUpdateService {
    
    func writeCL_RFIDControlDataUpdateRequest(operation: ControlDataOperation) {
        
        guard let cl_RFIDControlDataUpdateRequestData = operation.ylink.CL_RFIDControlDataUpdateRequest?.dataFromHexadecimalString() else {
            yCDLog(operation: operation, message: "Could not get cl_RFIDControlDataUpdateRequest - not writing update request.")
            operation.status = ControlDataOperation.Status.UpdateFailed
            self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(controlDataUpdateFailed: operation)
            return
        }
        
        guard let peripheral = operation.peripheral else {
            yCDLog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No peripheral ref. found in operation \(operation)!")
            return
        }
        
        guard let writeChar = operation.ylink.writeCharacteristic else {
            yCDLog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No reference found for Write Char!")
            return
        }
        
        yCDLog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "Writing CL_RFIDControlDataUpdateRequest: \n\(cl_RFIDControlDataUpdateRequestData.hexadecimalString())")
        
        if writeChar.properties.contains(CBCharacteristicProperties.Write) {
            peripheral.writeValue(cl_RFIDControlDataUpdateRequestData, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithResponse)
        }
        else if writeChar.properties.contains(CBCharacteristicProperties.WriteWithoutResponse) {
            peripheral.writeValue(cl_RFIDControlDataUpdateRequestData, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithoutResponse)
        }
    }
    
    func writeNextPL_CardKeyGroups(operation: ControlDataOperation) {
        
        guard let cardKeyGroupsData = operation.ylink.cardKeyGroups?.dataFromHexadecimalString() else {
            
            yCDLog(operation: operation, message: "No card key groups found to write. Value is nil.")
            writePL_CardKeyGroupsUploadComplete(operation)
            
            return
        }
        
        guard let peripheral = operation.peripheral else {
            yCDLog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No peripheral ref. found in operation \(operation)!")
            return
        }
        
        guard let writeChar = operation.ylink.writeCharacteristic else {
            yCDLog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No reference found for Write Char!")
            return
        }
        
        var chunkSize:Int = PL_CardKeyGroups.maxPacketSize
        
        if (operation.cardKeysGroupsOffset >= cardKeyGroupsData.length) {
            
            yCDLog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "All card Key groups written!")
            
            // stop here - all card keys groups sent
            writePL_CardKeyGroupsUploadComplete(operation)
            return
        }
        
        // Make sure we dont overflow on the last packet
        if (operation.cardKeysGroupsOffset + PL_CardKeyGroups.maxPacketSize > cardKeyGroupsData.length) {
            chunkSize = cardKeyGroupsData.length - operation.cardKeysGroupsOffset
        }
        
        let dataChunk = cardKeyGroupsData.subdataWithRange(NSMakeRange(operation.cardKeysGroupsOffset, chunkSize))
        
        let pl_cardKeyGroups = PL_CardKeyGroups()
        pl_cardKeyGroups.messageID = PL_CardKeyGroups.identity
        pl_cardKeyGroups.packetSize = UInt8(dataChunk.length)
        pl_cardKeyGroups.data = dataChunk.convertToBytes()
        
        yCDLog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "Writing PL_CardKeyGroups -- offset: \(operation.cardKeysGroupsOffset) packetSize: \(dataChunk.length) data: \(pl_cardKeyGroups.rawData!.hexadecimalString())")
        
        if writeChar.properties.contains(CBCharacteristicProperties.Write) {
            peripheral.writeValue(pl_cardKeyGroups.rawData!, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithResponse)
        }
        else if writeChar.properties.contains(CBCharacteristicProperties.WriteWithoutResponse) {
            peripheral.writeValue(pl_cardKeyGroups.rawData!, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithoutResponse)
        }
        
        operation.cardKeysGroupsOffset += chunkSize
        
        //        self.delegate?.RFIDControlDataEngine(controlDataWriteProgress: operation, bytesWritten: Int64(chunkSize), totalBytesWritten: Int64(operation.cardKeysGroupsOffset), totalBytesExpectedToWrite: Int64(dataChunk.length))
    }
    
    func writePL_CardKeyGroupsUploadComplete(operation: ControlDataOperation) {
        
        guard let peripheral = operation.peripheral else {
            yCDLog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No peripheral ref. found in operation \(operation)!")
            return
        }
        
        guard let writeChar = operation.ylink.writeCharacteristic else {
            yCDLog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No reference found for Write Char!")
            return
        }
        
        yCDLog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "Writing PL_CardKeyGroupsUploadComplete.")
        
        let pl_cardKeyGroupsUploadComplete = PL_CardKeyGroupsUploadComplete()
        pl_cardKeyGroupsUploadComplete.messageID = PL_CardKeyGroupsUploadComplete.identity
        
        operation.wrotePL_CardKeyGroupsUploadComplete = true
        
        if writeChar.properties.contains(CBCharacteristicProperties.Write) {
            peripheral.writeValue(pl_cardKeyGroupsUploadComplete.rawData!, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithResponse)
        }
        else if writeChar.properties.contains(CBCharacteristicProperties.WriteWithoutResponse) {
            peripheral.writeValue(pl_cardKeyGroupsUploadComplete.rawData!, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithoutResponse)
        }
    }
    
    func writeNextPL_CancelledStaffCards(operation: ControlDataOperation) {
        
        guard let cancelledStaffCardsData = operation.ylink.cancelledStaffCards?.dataFromHexadecimalString() else {
            
            yCDLog(operation: operation, message: "No cancelled staff cards found to write. Value is nil.")
            writePL_CancelledStaffCardDataUploadComplete(operation)
            
            return
        }
        
        guard let peripheral = operation.peripheral else {
            yCDLog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No peripheral ref. found in operation \(operation)!")
            return
        }
        
        guard let writeChar = operation.ylink.writeCharacteristic else {
            yCDLog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No reference found for Write Char!")
            return
        }
        
        var chunkSize:Int = PL_CancelledStaffCards.maxPacketSize
        
        if (operation.cancelledStaffCardsOffset >= cancelledStaffCardsData.length) {
            
            yCDLog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "All cancelled staff cards written!")
            
            // stop here - all cancelled staff cards sent
            writePL_CancelledStaffCardDataUploadComplete(operation)
            return
        }
        
        // Make sure we dont overflow on the last packet
        if (operation.cancelledStaffCardsOffset + PL_CardKeyGroups.maxPacketSize > cancelledStaffCardsData.length) {
            chunkSize = cancelledStaffCardsData.length - operation.cancelledStaffCardsOffset
        }
        
        let dataChunk = cancelledStaffCardsData.subdataWithRange(NSMakeRange(operation.cancelledStaffCardsOffset, chunkSize))
        
        let pl_cancelledStaffCards = PL_CancelledStaffCards()
        pl_cancelledStaffCards.messageID = PL_CancelledStaffCards.identity
        pl_cancelledStaffCards.packetSize = UInt8(dataChunk.length)
        pl_cancelledStaffCards.data = dataChunk.convertToBytes()
        
        yCDLog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "Writing PL_CancelledStaffCards -- offset: \(operation.cancelledStaffCardsOffset) packetSize: \(dataChunk.length) data: \(pl_cancelledStaffCards.rawData!.hexadecimalString())")
        
        if writeChar.properties.contains(CBCharacteristicProperties.Write) {
            peripheral.writeValue(pl_cancelledStaffCards.rawData!, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithResponse)
        }
        else if writeChar.properties.contains(CBCharacteristicProperties.WriteWithoutResponse) {
            peripheral.writeValue(pl_cancelledStaffCards.rawData!, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithoutResponse)
        }
        
        operation.cancelledStaffCardsOffset += chunkSize
        
        //        self.delegate?.RFIDControlDataEngine(controlDataWriteProgress: operation, bytesWritten: Int64(chunkSize), totalBytesWritten: Int64(operation.cardKeysGroupsOffset), totalBytesExpectedToWrite: Int64(dataChunk.length))
    }
    
    func writePL_CancelledStaffCardDataUploadComplete(operation: ControlDataOperation) {
        
        guard let peripheral = operation.peripheral else {
            yCDLog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No peripheral ref. found in operation \(operation)!")
            return
        }
        
        guard let writeChar = operation.ylink.writeCharacteristic else {
            yCDLog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No reference found for Write Char!")
            return
        }
        
        yCDLog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "Writing PL_CancelledStaffCardDataUploadComplete.")
        
        operation.status = ControlDataOperation.Status.WriteComplete
        self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(updateWriteComplete: operation)
        
        let pl_cancelledStaffCardDataUploadComplete = PL_CancelledStaffCardDataUploadComplete()
        pl_cancelledStaffCardDataUploadComplete.messageID = PL_CancelledStaffCardDataUploadComplete.identity
        
        operation.wrotePL_CancelledStaffCardDataUploadComplete = true
        
        if writeChar.properties.contains(CBCharacteristicProperties.Write) {
            peripheral.writeValue(pl_cancelledStaffCardDataUploadComplete.rawData!, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithResponse)
        }
        else if writeChar.properties.contains(CBCharacteristicProperties.WriteWithoutResponse) {
            peripheral.writeValue(pl_cancelledStaffCardDataUploadComplete.rawData!, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithoutResponse)
        }
    }
    
    func writePL_RFIDControlDataUpdateCompleteAck(operation: ControlDataOperation) {
        
        guard let peripheral = operation.peripheral else {
            yCDLog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No peripheral ref. found in operation \(operation)!")
            return
        }
        
        guard let writeChar = operation.ylink.writeCharacteristic else {
            yCDLog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No reference found for Write Char!")
            return
        }
        
        yCDLog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "Writing PL_RFIDControlDataUpdateCompleteAck.")
        
        let pl_RFIDControlDataUpdateCompleteAck = PL_RFIDControlDataUpdateCompleteAck()
        pl_RFIDControlDataUpdateCompleteAck.messageID = PL_RFIDControlDataUpdateCompleteAck.identity
        
        if writeChar.properties.contains(CBCharacteristicProperties.Write) {
            peripheral.writeValue(pl_RFIDControlDataUpdateCompleteAck.rawData!, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithResponse)
        }
        else if writeChar.properties.contains(CBCharacteristicProperties.WriteWithoutResponse) {
            peripheral.writeValue(pl_RFIDControlDataUpdateCompleteAck.rawData!, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithoutResponse)
        }
    }
    
}

extension ControlDataUpdateService {
    
    func didDiscoverPeripheral(peripheral: CBPeripheral, operation: ControlDataOperation, RSSI: NSNumber) {
        
        operation.peripheral = peripheral
        
        if operation.status == ControlDataOperation.Status.UpToDate {
            
            yCDLog(operation: operation, message: "Operation already up to date, ignoring discovery")
            return
            
        } else if operation.status == ControlDataOperation.Status.UpdateFailed {
            
            yCDLog(operation: operation, message: "Previously received a RFID LP_Disconnect reason: \(operation.lastDisconnectReason), not connecting")
            return
        }
        
        if abs(RSSI.integerValue) >= abs(minRSSIThreshold) {
            
            operation.latestRSSI = RSSI.integerValue
            self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(RSSIUpdate: RSSI.integerValue, operation: operation)
            
            self.updater?.restartScan()
            return
        }
        
        operation.numOfSightingWithinThreshold += 1
        
        if operation.numOfSightingWithinThreshold < minThresholdSighting {
            
            self.updater?.restartScan()
            return
        }
        
        // threshold reached, reset:
        operation.numOfSightingWithinThreshold = 0
        
        // In this case, the operation has been initiated but not verified on yC or needs a new verification
        // Dont allow operation to restart if we got disconnected for a reason
        if self.updater?.updateMode == .Automatic || operation.status != ControlDataOperation.Status.UnknownDisconnect {
            
            if (operation.status != ControlDataOperation.Status.Discovered) {
                operation.status = ControlDataOperation.Status.Discovered
                operation.restartOperation()
                self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(discoveredYLinkForOperation: operation)
            }
        }
        
        if self.updater?.updateMode == .Automatic {
            if numberOfActiveControlDataOperations() < maximumConcurrentUpdates {
                self.verifyUpdateIsNeeded(forOperation: operation)
            } else {
                self.updater?.restartScan()
            }
        }
    }
    
    func didConnectWithPeripheralForOperation(operation: ControlDataOperation) {
        
        yCDLog(operation: operation, message: "Did connect to \(operation.ylink.macAddress)")
        
        operation.status = ControlDataOperation.Status.Connected
        self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(didConnectWithYLink: operation)
    }
    
    func didDisconnectWithPeripheralForOperation(operation: ControlDataOperation, error: NSError?) {
        
        if (error?.code == 7) {
            
            yCDLog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): Did disconnect from peripheral: \(operation.peripheral).")
            
            if operation.lastDisconnectReason == nil && operation.status != ControlDataOperation.Status.UpToDate {
                
                operation.status = ControlDataOperation.Status.UnknownDisconnect
                yCDLog(LoggerLevel.Warning, category: LoggerCategory.BLE, operation: operation, message: "WARNING: CONTROL DATA OPERATION INTERRUPTED BY REMOTE YLINK")
            }
            
        } else {
            
            yCDLog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): Did disconnect from peripheral: \(operation.peripheral) error: \(error).")
        }
        
        self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(didDisconnectFromYLink: operation)
    }
    
}

extension ControlDataUpdateService {
    
    func didDiscoverCharacteristics(characteristics: [CBCharacteristic], operation: ControlDataOperation) {
        
        yCDLog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "Discovered characteristics:\n\(characteristics)")
        
        for characteristic in characteristics {
            
            if characteristic.UUID == self.writeCharacteristicUUID {
                
                operation.ylink.writeCharacteristic = characteristic
                yCDLog(operation: operation, message: "Subscribing to the Main Write Characteristic on \(operation.ylink)")
                operation.peripheral?.setNotifyValue(true, forCharacteristic: characteristic)
            }
        }
        
        if let _ = operation.ylink.writeCharacteristic {
            self.writeCL_RFIDControlDataUpdateRequest(operation)
            
            operation.status = ControlDataOperation.Status.Updating
            self.updater?.controlDataUpdateDelegate?.ControlDataUpdate(didStartUpdate: operation)
        }
        else {
            yCDLog(operation: operation, message: "Did not discover Write char, waiting for more...")
        }
    }
    
    func didUpdateValueForCharacteristic(characteristic: CBCharacteristic, operation: ControlDataOperation, error: NSError?) {
        
        yCDLog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "didUpdateValue characteristic : \(characteristic) value: \(characteristic.value)")
        
        if characteristic.UUID == self.writeCharacteristicUUID {
            
            yCDLog(operation: operation, message: "Write char update from \(operation.peripheral?.name) - checking Message Identity...")
            
            if let data = characteristic.value {
                self.processIncomingMessage(data, operation: operation)
            } else {
                yCDLog(operation: operation, message: "No value found on the characteristic update.")
            }
        }
    }
    
    func didWriteValueForCharacteristic(characteristic: CBCharacteristic, operation: ControlDataOperation, error: NSError?) {
        
        if characteristic.UUID == self.writeCharacteristicUUID {
            yCDLog(operation: operation, message: "Received confirmation from the writeCharacteristic on yLink for room: \(operation.ylink.roomNumber)")
            
            handleIncomingWriteConfirmation(characteristic.value, operation: operation)
        }
    }
    
}

