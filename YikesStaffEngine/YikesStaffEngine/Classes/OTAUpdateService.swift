//
//  OTAUpdateService.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/26/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import AVFoundation
import CoreBluetooth
import TaskQueue

public protocol OTAUpdateDelegate: class {
    func OTAUpdate(foundUpdatesForOperations operations: [OTAOperation])
    func OTAUpdate(startedScanningForYLinks operations: [OTAOperation])
    func OTAUpdate(RSSIUpdate RSSI: Int, operation: OTAOperation)
    func OTAUpdate(discoveredYLinkForOperation operation: OTAOperation)
    func OTAUpdate(verifyingOperation operation: OTAOperation)
    func OTAUpdate(operationVerifyFailed operation: OTAOperation)
    func OTAUpdate(operationVerifyPassed operation: OTAOperation)
    func OTAUpdate(downloadingFirmware operation: OTAOperation, bytesRead: Int64, totalBytesRead: Int64, totalBytesExpectedToRead: Int64)
    func OTAUpdate(firmwareDownloadFailed operation: OTAOperation, error: NSError)
    func OTAUpdate(firmwareDownloadComplete operation: OTAOperation)
    func OTAUpdate(didConnectWithYLink operation: OTAOperation)
    func OTAUpdate(didStartUpdate operation: OTAOperation) // received LP_StartFirmwareUpload
    func OTAUpdate(firmwareWriteProgress operation: OTAOperation, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    func OTAUpdate(firmwareWriteFailed operation: OTAOperation) // received FIRMWARE_TOO_SMALL, FIRMWARE_TOO_BIG, FIRMWARE_FAILED_CRC, INACTIVITY_TIMEOUT
    func OTAUpdate(firmwareWriteComplete operation: OTAOperation) // received FIRMWARE_UPLOAD_CONFIRMED
    func OTAUpdate(validatingUpdateForOperation operation: OTAOperation) // the yLink had received the firmware, rebooted and now it's discovered again - waiting for the LC_FirmwareUpdateComplete to confirm the update
    func OTAUpdate(firmwareUpdateConfirmed operation: OTAOperation) // received LC_FirmwareUpdateComplete
    func OTAUpdate(firmwareUpdateFailed operation: OTAOperation) // received FIRMWARE_FAILED_TO_BOOT
    func OTAUpdate(didDisconnectFromYLink operation: OTAOperation)
    func OTAUpdate(operationRemovedFromScanList operation: OTAOperation)
}

class OTAUpdateService {
    
    weak var updater : YLinkUpdater?
    
    let taskQueue = TaskQueue()
    var operations : [OTAOperation] = []
    
    let minRSSIThreshold = -75
    let minThresholdSighting = 2
    let firmwarePacketDelay = 0.008 // in seconds
    let maximumConcurrentOTAUpdates = 3
    
    let packetSize: Int = 14
    
    let writeCharacteristicUUID = CBUUID(string: BLEConstants.writeCharacteristicUUID)
    let otaCharacteristicUUID = CBUUID(string: BLEConstants.otaCharacteristicUUID)
    
    init(updater: YLinkUpdater) {
        
        self.updater = updater
    }
    
    func restartAllOperations(forCentralManager centralManager: CBCentralManager) {
        
        defer {
            self.updater?.otaUpdateDelegate?.OTAUpdate(foundUpdatesForOperations: operations)
            self.updater?.otaUpdateDelegate?.OTAUpdate(startedScanningForYLinks: operations)
        }
        
        self.operations.endAllOperations()
        self.operations.removeAll()
        
        guard let ylinksWithNewFirmware = updater?.currentHotel.ylinksWithOTAUpdates?.ylinksWithNewFirmware() else {
            return
        }
        
        for ylink in ylinksWithNewFirmware {
            let operation = OTAOperation(ylink: ylink)
            operation.centralManager = centralManager
            self.operations.append(operation)
            
            operation.status = OTAOperation.Status.Scanning
        }
    }
    
    func removeOperationFromList(operation: OTAOperation) {
        
        self.updater?.otaUpdateDelegate?.OTAUpdate(operationRemovedFromScanList: operation)
        
        defer {
            operation.endOperation()
            operations = operations.filter { $0 !== operation }
            self.updater?.restartScan()
        }
        
        guard let ylinks = self.updater?.currentHotel.ylinksWithOTAUpdates else {
            return
        }
        
        self.updater?.currentHotel.ylinksWithOTAUpdates = ylinks.filter { $0 !== operation.ylink }
    }
    
    func operationForYLinkUUID(UUIDToFind: CBUUID) -> OTAOperation? {
        
        for operation in operations {
            if operation.ylink.uuid == UUIDToFind {
                return operation
            }
        }
        return nil
    }
    
    func operationForPeripheral(peripheralToFind: CBPeripheral) -> OTAOperation? {
        
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
    
    func verifyUpdateIsNeeded(forOperation operation: OTAOperation) {
        
        yOTALog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): Verifying update.")
        
        operation.status = OTAOperation.Status.VerifyingUpdate
        self.updater?.otaUpdateDelegate?.OTAUpdate(verifyingOperation: operation)
        
        self.updater?.currentHotel.getYLink(operation.ylink.yLinkId!, success: { ylink in
            
            guard let _ = ylink.newFirmware else {
                
                operation.status = OTAOperation.Status.UpdateVerifyFailed
                self.updater?.otaUpdateDelegate?.OTAUpdate(operationVerifyFailed: operation)
                
                yOTALog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "YLink doesn't have any new firmware, removing from list: \n\(ylink).")
                self.removeOperationFromList(operation)
                
                return
            }
            
            yOTALog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): Update verified from server.")
            
            operation.status = OTAOperation.Status.UpdateVerified
            self.updater?.otaUpdateDelegate?.OTAUpdate(operationVerifyPassed: operation)
            
            operation.ylink = ylink
            
            if (self.updater?.updateMode == .Automatic || operation.requiresManualUpdate() == true) {
                self.startOTAForOperation(operation)
            }
            
        }, failure: { error in
            
            operation.status = OTAOperation.Status.UpdateVerifyFailed
            self.updater?.otaUpdateDelegate?.OTAUpdate(operationVerifyFailed: operation)
            
            yOTALog(LoggerLevel.Error, category: LoggerCategory.API, operation: operation, message: "Verify update request for \(operation.ylink.roomNumber) failed: \(error)")
        })
    }
    
    // Queuing up tasks here for the case of starting multiple OTA operations at once. Prevents duplicate hex downloads.
    func startOTAForOperation(operation: OTAOperation) {
        
        yOTALog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): Starting OTA for room \(operation.ylink.roomNumber).")
        
        taskQueue.tasks +=~ { result, next in
            
            FirmwareFileHelper.downloadFirmware(forYLink: operation.ylink,
                progress: { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                                                    
                    operation.status = OTAOperation.Status.DownloadingFirmware
                    self.updater?.otaUpdateDelegate?.OTAUpdate(downloadingFirmware: operation, bytesRead: bytesRead, totalBytesRead: totalBytesRead, totalBytesExpectedToRead: totalBytesExpectedToRead)
                    
                }, success: {
                    
                    operation.status = OTAOperation.Status.FirmwareDownloadComplete
                    self.updater?.otaUpdateDelegate?.OTAUpdate(firmwareDownloadComplete: operation)
                    
                    next(true)
                    
                }, failure: { error in
                    
                    if let err = error {
                        operation.status = OTAOperation.Status.FirmwareDownloadFailed
                        self.updater?.otaUpdateDelegate?.OTAUpdate(firmwareDownloadFailed: operation, error: err)
                    }
                    next(false)
            })
        }
        
        taskQueue.tasks +=~ { result, next in
            
            guard let result = result as? Bool else {
                next(nil)
                return
            }
            
            if result == false {
                yOTALog(LoggerLevel.Error, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): Firmware download failed, not continuing OTA.")
                next(nil)
                return
            }
            
            guard let peripheral = operation.peripheral else {
                
                yOTALog(LoggerLevel.Error, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): No peripheral found to connect with.")
                
                operation.status = OTAOperation.Status.Scanning
                self.updater?.otaUpdateDelegate?.OTAUpdate(startedScanningForYLinks: [operation])
                
                self.updater?.restartScan()
                
                next(nil)
                return
            }
            
            operation.startOperation()
            
            yOTALog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): OTA operation started at \(operation.start).")
            yOTALog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): Connecting with peripheral: \(peripheral).")
            
            // Firmware file is ready for transfer, connect to yLink and initiate update:
            operation.centralManager?.connectPeripheral(peripheral, options: nil)
            
            next(nil)
        }
        
        taskQueue.run()
    }
    
    func numberOfActiveOTAOperations() -> Int {
        
        var count = 0
        for operation in operations {
            if operation.isInProgress == true {
                count += 1
            }
        }
        return count
    }
}

extension OTAUpdateService {
    
    private func writePL_FirmwareUpdateRequest(operation:OTAOperation) {
        
        guard let cl_FirmwareUpdateRequestData = operation.ylink.newFirmware?.CL_FirmwareUpdateRequest?.dataFromHexadecimalString() else {
            yOTALog(operation: operation, message: "Could not get cl_FirmwareUpdateRequestData - stopping operation for room \(operation.ylink.roomNumber)")
            operation.status = OTAOperation.Status.UnknownDisconnect
            self.updater?.otaUpdateDelegate?.OTAUpdate(didDisconnectFromYLink: operation)
            return
        }
        
        let cl_FirmwareUpdateRequest = CL_FirmwareUpdateRequest(rawData: cl_FirmwareUpdateRequestData)
        
        let pl_FirmwareUpdateRequest = PL_FirmwareUpdateRequest()
        pl_FirmwareUpdateRequest.messageID = PL_FirmwareUpdateRequest.identity
        pl_FirmwareUpdateRequest.messageVersion = 0x01
        if let cl_FR = cl_FirmwareUpdateRequest?.rawData?.convertToBytes() {
            pl_FirmwareUpdateRequest.CL_firmwareUpdateRequest = cl_FR
        }
        
        if let peripheral = operation.peripheral, let writeChar = operation.ylink.writeCharacteristic, let data = pl_FirmwareUpdateRequest.rawData {
            
            yOTALog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): Writing PL_FirmwareUpdateRequest: \(pl_FirmwareUpdateRequest.rawData).")
            
            if writeChar.properties.contains(CBCharacteristicProperties.Write) {
                peripheral.writeValue(data, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithResponse)
            }
            else if writeChar.properties.contains(CBCharacteristicProperties.WriteWithoutResponse) {
                peripheral.writeValue(data, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithoutResponse)
            }
            else {
                //TODO: Log / Show error to user
            }
        }
        
    }
    
    private func startFirmwareTransfer(operation:OTAOperation) {
        
        if operation.otaTransferTimer != nil {
            yOTALog(LoggerLevel.Warning, category: LoggerCategory.Engine, operation: operation, message: "OTA Transfer already started for this operation: \(operation)\n --ignoring")
        } else {
            
            guard let firmwareData = FirmwareFileHelper.firmwareData(forYLink: operation.ylink) else {
                yOTALog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No data found in the firmware file! Not starting OTA.")
                return
            }
            operation.firmwareData = firmwareData
            
            let otaTimer : dispatch_source_t = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.updater!.queue);
            operation.otaTransferTimer = otaTimer
            
            dispatch_source_set_timer(otaTimer, DISPATCH_TIME_NOW, UInt64(firmwarePacketDelay * Double(NSEC_PER_SEC)), 0 * NSEC_PER_SEC)
            dispatch_source_set_event_handler(otaTimer, {
                self.sendNextFirmwarePacket(operation)
            });
            dispatch_resume(otaTimer);
        }
    }
    
    private func sendNextFirmwarePacket(operation:OTAOperation) {
        
        guard let otaTimer = operation.otaTransferTimer else {
            yOTALog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No otaTimer ref. found in Operation \(operation)!")
            return
        }
        
        guard let peripheral = operation.peripheral else {
            yOTALog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No Peripheral ref. found in Operation \(operation)!")
            return
        }
        
        guard let otaChar = operation.ylink.otaCharacteristic else {
            yOTALog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No reference found for OTA Char!")
            return
        }
        
        guard let data = operation.firmwareData else {
            yOTALog(LoggerLevel.Critical, category: LoggerCategory.System, operation: operation, message: "No data found in the firmware file!")
            return
        }
        
        
        var chunkSize : Int = self.packetSize
        
        if (operation.offset >= data.length) {
            // end OTA
            
            dispatch_source_cancel(otaTimer);
            operation.otaTransferTimer = nil
            operation.transferEndDate = NSDate()
            
            yOTALog(operation: operation, message: "Finally you sent \(Int(data.length/chunkSize)) packets! Congratulations!")
            
            let delay = operation.writePL_FirmwareUploadCompleteDelay
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
            yOTALog(operation: operation, message: String(format: "Writing PL_FirmwareUploadComplete in %.2f seconds", operation.writePL_FirmwareUploadCompleteDelay))
            
            dispatch_after(delayTime, self.updater!.queue, {
                // Make sure the operation has not restarted and the offset is still ok:
                if operation.status == OTAOperation.Status.Updating
                    && operation.offset >= data.length {
                    self.writePL_FirmwareUploadComplete(operation)
                }
                else {
                    yOTALog(operation: operation, message: "Not writing PL_FirmwareUploadComplete - Operation status has changed to \(operation.status) and operation is for room \(operation.ylink.roomNumber)")
                }
            })
            return
        }
        
        // Make sure we dont overflow on the last packet
        if (operation.offset + self.packetSize > data.length) {
            chunkSize = data.length - operation.offset
        }
        
        let dataChunk = data.subdataWithRange(NSMakeRange(operation.offset, chunkSize))
        
        let pl_firmware = PL_Firmware()
        pl_firmware.messageID = PL_Firmware.identity
        pl_firmware.byteOffset = UInt32(operation.offset)
        pl_firmware.firmwarePacketSize = UInt8(dataChunk.length)
        pl_firmware.firmwarePacket = dataChunk.convertToBytes()
        
        
        if (operation.offset == 0) {
            operation.transferStartDate = NSDate()
            yOTALog(operation: operation, message: "Going to write in chunks of \(chunkSize) bytes at intervals of \(firmwarePacketDelay*1000) ms.")
        }
        
        
        if peripheral.state == CBPeripheralState.Connected {
            peripheral.writeValue(pl_firmware.rawData!, forCharacteristic: otaChar, type: CBCharacteristicWriteType.WithoutResponse)
            
//            yOTALog(operation: operation, message: "PL_Firmware:\n" + pl_firmware.description)
            
            let totalBytesWritten = Int64(operation.offset)
            let totalBytesExpectedToWrite = Int64(data.length)
            
            print("wrote \(totalBytesWritten)/\(totalBytesExpectedToWrite)")
            
            operation.offset += chunkSize
            operation.OTAProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            
            self.updater?.otaUpdateDelegate?.OTAUpdate(firmwareWriteProgress: operation, bytesWritten: Int64(chunkSize), totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
        else {
            
            dispatch_source_cancel(otaTimer);
            operation.otaTransferTimer = nil
            
            yOTALog(operation: operation, message: "Stopping OTA Transfer Timer for room \(operation.ylink.roomNumber) - peripheral is no longer connected.")
        }
    }
    
    private func writePL_FirmwareUploadComplete(operation: OTAOperation) {
        
        guard let writeChar = operation.ylink.writeCharacteristic,
            let peripheral = operation.peripheral else {
                return
        }
        
        let pl_firmwareUploadComplete = PL_FirmwareUploadComplete()
        pl_firmwareUploadComplete.messageID = PL_FirmwareUploadComplete.identity
        
        let rawData = pl_firmwareUploadComplete.rawData!
        
        yOTALog(operation: operation, message: "Writing the PL_FirmwareUploadComplete: \(pl_firmwareUploadComplete) to ylink \(operation.ylink) and characteristic \(writeChar)")
        
        if writeChar.properties.contains(CBCharacteristicProperties.Write) {
            yOTALog(operation: operation, message: "Writing WITH response: \(rawData)")
            peripheral.writeValue(rawData, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithResponse)
        }
        else if writeChar.properties.contains(CBCharacteristicProperties.WriteWithoutResponse) {
            yOTALog(operation: operation, message: "Writing WITHOUT response: \(rawData)")
            peripheral.writeValue(rawData, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithoutResponse)
        }
        else {
            yOTALog(.Error, operation: operation, message: "\(writeChar) is not writeable - skipping")
            //TODO: Log / Show error to user
        }
        
    }
}

extension OTAUpdateService {
    
    private func processDisconnectMessage(operation:OTAOperation, data:NSData) {
        
        guard let lp_disconnect = LP_Disconnect(rawData: data) else { return }
        
        if let disconnectReasonCode = lp_disconnect.disconnectReason {
            
            switch (disconnectReasonCode) {
                
            case OTAOperation.DisconnectReason.FIRMWARE_TOO_SMALL.rawValue:
                operation.lastDisconnectReason = OTAOperation.DisconnectReason.FIRMWARE_TOO_SMALL
                operation.end = NSDate()
                operation.OTAProgress = 0
                
                yOTALog(operation: operation, message: "Received an LP_Disconnect message \(OTAOperation.DisconnectReason.FIRMWARE_TOO_SMALL)")
                
                operation.status = OTAOperation.Status.FailedToWrite
                self.updater?.otaUpdateDelegate?.OTAUpdate(firmwareWriteFailed: operation)
                
                reportFirmwareStatus(operation, reason: OTAOperation.DisconnectReason.FIRMWARE_TOO_SMALL)
                
                break
                
            case OTAOperation.DisconnectReason.FIRMWARE_TOO_BIG.rawValue:
                operation.lastDisconnectReason = OTAOperation.DisconnectReason.FIRMWARE_TOO_BIG
                operation.end = NSDate()
                operation.OTAProgress = 0
                
                yOTALog(operation: operation, message: "Received an LP_Disconnect message \(OTAOperation.DisconnectReason.FIRMWARE_TOO_BIG)")
                
                operation.status = OTAOperation.Status.FailedToWrite
                self.updater?.otaUpdateDelegate?.OTAUpdate(firmwareWriteFailed: operation)
                
                reportFirmwareStatus(operation, reason: OTAOperation.DisconnectReason.FIRMWARE_TOO_BIG)
                
                break
                
            case OTAOperation.DisconnectReason.FIRMWARE_FAILED_CRC.rawValue:
                operation.lastDisconnectReason = OTAOperation.DisconnectReason.FIRMWARE_FAILED_CRC
                operation.end = NSDate()
                operation.OTAProgress = 0
                
                yOTALog(operation: operation, message: "Received an LP_Disconnect message \(OTAOperation.DisconnectReason.FIRMWARE_FAILED_CRC)")
                
                operation.status = OTAOperation.Status.FailedToWrite
                self.updater?.otaUpdateDelegate?.OTAUpdate(firmwareWriteFailed: operation)
                
                reportFirmwareStatus(operation, reason: OTAOperation.DisconnectReason.FIRMWARE_FAILED_CRC)
                
                break
                
            case OTAOperation.DisconnectReason.FIRMWARE_UPLOAD_CONFIRMED.rawValue:
                operation.lastDisconnectReason = OTAOperation.DisconnectReason.FIRMWARE_UPLOAD_CONFIRMED
                // The yLink will now reboot and we should reconnect when it reappears - waiting for the peripheralManager disconnect callback
                
                yOTALog(operation: operation, message: "Received an LP_Disconnect message \(OTAOperation.DisconnectReason.FIRMWARE_UPLOAD_CONFIRMED)")
                
                operation.status = OTAOperation.Status.WriteComplete
                self.updater?.otaUpdateDelegate?.OTAUpdate(firmwareWriteComplete: operation)
                
                // TODO: add time to update
                reportFirmwareStatusWithTime(operation, reason: OTAOperation.DisconnectReason.FIRMWARE_UPLOAD_CONFIRMED, timeToUpdate: 0)
                
                break
                
            case OTAOperation.DisconnectReason.INACTIVITY_TIMEOUT.rawValue:
                operation.lastDisconnectReason = OTAOperation.DisconnectReason.INACTIVITY_TIMEOUT
                operation.end = NSDate()
                operation.OTAProgress = 0
                
                yOTALog(operation: operation, message: "Received an LP_Disconnect message \(OTAOperation.DisconnectReason.INACTIVITY_TIMEOUT)")
                // Reconnect when in good range
                
                operation.status = OTAOperation.Status.FailedToWrite
                self.updater?.otaUpdateDelegate?.OTAUpdate(firmwareWriteFailed: operation)
                
                reportFirmwareStatus(operation, reason: OTAOperation.DisconnectReason.INACTIVITY_TIMEOUT)
                
                break
                
            case OTAOperation.DisconnectReason.FIRMWARE_FAILED_TO_BOOT.rawValue:
                operation.lastDisconnectReason = OTAOperation.DisconnectReason.FIRMWARE_FAILED_TO_BOOT
                operation.end = NSDate()
                operation.OTAProgress = 0
                
                yOTALog(operation: operation, message: "Received an LP_Disconnect message \(OTAOperation.DisconnectReason.FIRMWARE_FAILED_TO_BOOT)")
                
                operation.status = OTAOperation.Status.UpdateFailed
                self.updater?.otaUpdateDelegate?.OTAUpdate(firmwareUpdateFailed: operation)
                
                reportFirmwareStatus(operation, reason: OTAOperation.DisconnectReason.FIRMWARE_FAILED_TO_BOOT)
                
                break
                
            default:
                yOTALog(operation: operation, message: "Disconnect reason code not handled (yet): \(disconnectReasonCode)")
            }
            
            
        }
    }
    
    func reportFirmwareStatus(operation: OTAOperation, reason: OTAOperation.DisconnectReason) {
        
        self.updater?.currentHotel.updateFirmwareStatus(Int(reason.rawValue), ylink: operation.ylink, success: {
            
            yOTALog(LoggerLevel.Debug, category: LoggerCategory.API, operation: operation, message: "Successfully sent firmware update status: \(reason).")
            
        }) { error in
            
            yOTALog(LoggerLevel.Error, category: LoggerCategory.API, operation: operation, message: "Failed to send firmware update status: \(reason).")
        }
    }
    
    func reportFirmwareStatusWithTime(operation: OTAOperation, reason: OTAOperation.DisconnectReason, timeToUpdate: Int) {
        
        self.updater?.currentHotel.updateFirmwareStatus(Int(reason.rawValue), timeToUpdate: timeToUpdate, ylink: operation.ylink, success: {
            
            yOTALog(LoggerLevel.Debug, category: LoggerCategory.API, operation: operation, message: "Successfully sent firmware update status: \(reason) timeToUpdate: \(timeToUpdate).")
            
        }) { (error) in
            
            yOTALog(LoggerLevel.Error, category: LoggerCategory.API, operation: operation, message: "Failed to send firmware update status: \(reason) timeToUpdate: \(timeToUpdate).")
        }
    }
}

extension OTAUpdateService {
    
    func didDiscoverPeripheral(peripheral: CBPeripheral, operation: OTAOperation, RSSI: NSNumber) {
        
        operation.peripheral = peripheral
        
        if operation.status == OTAOperation.Status.UpToDate {
            
            yOTALog(operation: operation, message: "Operation already up to date, ignoring discovery")
            return
            
        } else if operation.status == OTAOperation.Status.UpdateFailed {
            
            yOTALog(operation: operation, message: "Previously received a FIRMWARE_FAILED_TO_BOOT, not connecting")
            return
            
        } else if operation.status == OTAOperation.Status.WriteComplete ||
            operation.status == OTAOperation.Status.ValidatingUpdate {
            
            // Connect directly if we previously wrote firmware to yLink
            
            operation.OTAProgress = 0
            
            operation.status = OTAOperation.Status.ValidatingUpdate
            self.updater?.otaUpdateDelegate?.OTAUpdate(validatingUpdateForOperation: operation)
            
            // Attempt to reconnect - it should then get an LC_FirmwareUpdateComplete if the transfer and yL boot went OK:
            operation.centralManager?.connectPeripheral(peripheral, options: nil)
            
            return
        }
        
        if abs(RSSI.integerValue) >= abs(minRSSIThreshold) {
            
            operation.latestRSSI = RSSI.integerValue
            self.updater?.otaUpdateDelegate?.OTAUpdate(RSSIUpdate: RSSI.integerValue, operation: operation)
            
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
        // Dont update UI if we got disconnected without a reason
        if self.updater?.updateMode == .Automatic || operation.status != OTAOperation.Status.UnknownDisconnect {
            
            if (operation.status != OTAOperation.Status.Discovered) {
                operation.status = OTAOperation.Status.Discovered
                operation.restartOperation()
                self.updater?.otaUpdateDelegate?.OTAUpdate(discoveredYLinkForOperation: operation)
            }
        }
        
        if self.updater?.updateMode == .Automatic {
            if numberOfActiveOTAOperations() < maximumConcurrentOTAUpdates {
                self.verifyUpdateIsNeeded(forOperation: operation)
            } else {
                self.updater?.restartScan()
            }
        }
    }
    
    func didConnectWithPeripheralForOperation(operation: OTAOperation) {
        
        yOTALog(operation: operation, message: "Did connect to \(operation.ylink.macAddress)")
        
        // dont update UI if just confirming update after FIRMWARE_UPLOAD_CONFIRMED
        if operation.status != OTAOperation.Status.ValidatingUpdate {
            operation.status = OTAOperation.Status.Connected
            self.updater?.otaUpdateDelegate?.OTAUpdate(didConnectWithYLink: operation)
        }
    }
    
    func didDisconnectWithPeripheralForOperation(operation: OTAOperation, error: NSError?) {
        
        if (error?.code == 7) {
            
            yOTALog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): Did disconnect from peripheral: \(operation.peripheral).")
            
            if operation.lastDisconnectReason == nil {
                
                operation.OTAProgress = 0
                operation.status = OTAOperation.Status.UnknownDisconnect
                yOTALog(LoggerLevel.Warning, category: LoggerCategory.BLE, operation: operation, message: "WARNING: OTA OPERATION INTERRUPTED BY REMOTE YLINK")
            }
            
        } else {
            
            yOTALog(LoggerLevel.Debug, category: LoggerCategory.System, operation: operation, message: "\(operation.ylink.macAddress): Did disconnect from peripheral: \(operation.peripheral) error: \(error).")
        }
        
        self.updater?.otaUpdateDelegate?.OTAUpdate(didDisconnectFromYLink: operation)
    }
}

extension OTAUpdateService {
    
    func didDiscoverCharacteristics(characteristics: [CBCharacteristic], operation: OTAOperation) {
        
        yOTALog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "Discovered characteristics:\n\(characteristics)")
        
        for characteristic in characteristics {
            
            if characteristic.UUID == self.writeCharacteristicUUID {
                
                operation.ylink.writeCharacteristic = characteristic
                yOTALog(operation: operation, message: "Subscribing to the Main Write Characteristic on \(operation.ylink)")
                operation.peripheral?.setNotifyValue(true, forCharacteristic: characteristic)
            }
            else if characteristic.UUID == self.otaCharacteristicUUID {
                
                operation.ylink.otaCharacteristic = characteristic
            }
        }
        
        if let _ = operation.ylink.otaCharacteristic, let _ = operation.ylink.writeCharacteristic {
            self.writePL_FirmwareUpdateRequest(operation)
        }
        else {
            yOTALog(operation: operation, message: "Did not discover both Write and OTA char, waiting for more...")
        }
    }
    
    func didUpdateValueForCharacteristic(characteristic: CBCharacteristic, operation: OTAOperation, error: NSError?) {
        
        yOTALog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "didUpdateValue characteristic : \(characteristic) value: \(characteristic.value)")
        
        if characteristic.UUID == self.writeCharacteristicUUID {
            
            yOTALog(operation: operation, message: "Write char update from \(operation.peripheral?.name) - checking Message Identity...")
            
            if let data = characteristic.value {
                
                if LP_StartFirmwareUpload.isThisMessageType(data) {
                    
                    yOTALog(operation: operation, message: "Identified incoming LP_StartFirmwareUpload... mapping... ")
                    
                    if let lp_startFirmwareUpload = LP_StartFirmwareUpload(rawData: data) {
                        
                        operation.lp_startFirmwareUpload = lp_startFirmwareUpload
                        operation.offset = Int(lp_startFirmwareUpload.startingOffset)
                        
                        yOTALog(operation: operation, message: "Starting / Resuming Hex Transfer at offset \(operation.offset)")
                        
                        if operation.status != OTAOperation.Status.Updating {
                            self.updater?.otaUpdateDelegate?.OTAUpdate(didStartUpdate: operation)
                        }
                        operation.status = OTAOperation.Status.Updating
                        
                        self.startFirmwareTransfer(operation)
                    }
                    else {
                        yOTALog(LoggerLevel.Critical, category: LoggerCategory.BLE, operation: operation, message: "LP_StartFirmwareUpload Mapping error")
                    }
                }
                    
                else if LP_Disconnect.isThisMessageType(data) {
                    yOTALog(operation: operation, message: "Identified incoming LP_Disconnect... mapping... ")
                    self.processDisconnectMessage(operation, data:data)
                }
                    
                else if LC_FirmwareUpdateComplete.isThisMessageType(data) {
                    
                    guard let lc_FirmwareUpdateComplete = LC_FirmwareUpdateComplete(rawData: data) else {
                        yOTALog(LoggerLevel.Error, category: LoggerCategory.BLE, operation: operation, message: "LC_FirmwareUpdateComplete mapping failed:\nRaw data was: \(data)")
                        return
                    }
                    
                    if operation.lc_FirmwareUpdateComplete == nil {
                        
                        operation.lc_FirmwareUpdateComplete = lc_FirmwareUpdateComplete
                        yOTALog(operation: operation, message: "Detected incoming LC_FirmwareUpdateComplete -> Sending a read request.")
                        
                        if let peripheral = operation.peripheral, let writeCharacteristic = operation.ylink.writeCharacteristic {
                            peripheral.readValueForCharacteristic(writeCharacteristic)
                        }
                        else {
                            yOTALog(.Warning, category:.BLE, operation: operation, message:"lc_FirmwareUpdateComplete - Missing peripheral reference to readValueForCharacteristic for room: \(operation.ylink.roomNumber)")
                        }
                        
                    } else {
                        
                        yOTALog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "Received full LC_FirmwareUpdateComplete message:\n\(lc_FirmwareUpdateComplete)")
                        
                        // to play sound
                        AudioServicesPlaySystemSound (1010)
                        
                        let lcFirmUpdComplHexStr = data.hexadecimalString()
                        
                        operation.OTAProgress = 0
                        operation.status = OTAOperation.Status.UpToDate
                        self.updater?.otaUpdateDelegate?.OTAUpdate(firmwareUpdateConfirmed: operation)
                        
                        if let pl_firmwareUpdateCompleteAck_data = PL_FirmwareUpdateCompleteAck().rawData, let writeChar = operation.ylink.writeCharacteristic {
                            
                            yOTALog(LoggerLevel.Debug, category: LoggerCategory.BLE, operation: operation, message: "Writing PL_FirmwareUpdateCompleteAck")
                            
                            if writeChar.properties.contains(CBCharacteristicProperties.Write) {
                                operation.peripheral?.writeValue(pl_firmwareUpdateCompleteAck_data, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithResponse)
                            }
                            else if writeChar.properties.contains(CBCharacteristicProperties.WriteWithoutResponse) {
                                operation.peripheral?.writeValue(pl_firmwareUpdateCompleteAck_data, forCharacteristic: writeChar, type: CBCharacteristicWriteType.WithoutResponse)
                            }
                        }
                        
                        self.updater?.currentHotel.sendFirmwareUpdateComplete(lcFirmUpdComplHexStr, ylink: operation.ylink, success:
                            {
                                yOTALog(LoggerLevel.Debug, category: LoggerCategory.API, operation: operation, message: "Successfully sent LC_FirmwareUpdateComplete to yC.")
                                
//                                AudioServicesPlaySystemSound (1025)
                            }, failure: { (error) in
                                
                                yOTALog(LoggerLevel.Error, category: LoggerCategory.API, operation: operation, message: "Failed to send LC_FirmwareUpdateComplete to yC. \nError: \(error?.localizedFailureReason)")
                                
//                                self.otaReportsQueue?.otaReports?.append(OTAReport(
//                                    lc_FirmwareUpdateComplete: lcFirmUpdComplHexStr,
//                                    firmwareId: operation.ylink.newFirmware!.firmwareId!,
//                                    hotelId: self.currentHotel.hotelId!,
//                                    yLinkId: operation.ylink.yLinkId!))
                                
                                
//                                AudioServicesPlaySystemSound (1073)
                        })
                        
                        operation.lc_FirmwareUpdateComplete = nil
                        operation.end = NSDate()
                        
                        // remove operation
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3.0 * Double(NSEC_PER_SEC))), self.updater!.queue) {
                            self.removeOperationFromList(operation)
                        }
                    }
                }
                    
                else {
                    yOTALog(LoggerLevel.Critical, category: LoggerCategory.BLE, operation: operation, message: "Unidentified Message: \(data)")
                }
            }
                
            else {
                yOTALog(operation: operation, message: "No value found on the characteristic update.")
            }
        }
    }
    
    func didWriteValueForCharacteristic(characteristic: CBCharacteristic, operation: OTAOperation, error: NSError?) {
        
        if characteristic.UUID == self.writeCharacteristicUUID {
            yOTALog(operation: operation, message: "Received confirmation from the writeCharacteristic on yLink for room: \(operation.ylink.roomNumber)")
        }
    }
    
}
