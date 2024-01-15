//
//  YLinkReporter.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import CoreBluetooth

private class PL_GetReport: Message {
    override class var identity : UInt8 { return 0x70 } // 112
}

private class LP_NoReport: Message {
    override class var identity : UInt8 { return 0x71 } // 113
}

private class LC_Report: Message {
    override class var identity : UInt8 { return 0x6E } // 110
    
    var messageID : UInt8?
    var messageVersion : UInt8?
    var payloadLength : UInt8?
    var initializationVector : [UInt8] = []
    var payload: [UInt8] = []
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID                       <- map[start: 0, length: 1]
        messageVersion                  <- map[start: 1, length: 1]
        payloadLength                   <- map[start: 2, length: 1]
        initializationVector            <- map[start: 3, length: 16]
        payload                         <- map[toEndFrom: 19]
    }
}

private class YLinkReportOperation {
    
    var macAddress: String
    var peripheral: CBPeripheral?
    var writeCharacteristic: CBCharacteristic?
    
    var readingFullLC_Report: Bool = false
    var lastTimeReceivedLP_NoReport: NSDate?
    
    var pendingLC_ReportUploads: Int = 0
    var unwrittenCL_ReportAcks: [String] = []
    
    init(macAddress: String) {
        self.macAddress = macAddress
    }
}

class YLinkReporter: NSObject {
    
    let queue = dispatch_queue_create("com.yikesteam.staffapp.ylinkreporter", DISPATCH_QUEUE_SERIAL)
    var centralManager : CBCentralManager!
    
    private var scanTimer : dispatch_source_t?
    private let scanTimerIntervalSeconds = 10.0
    
    private let secondsToWaitSinceLastLP_NoReport = 30.0
    
    private var operations : [YLinkReportOperation] = []
    
    private let yLinkServiceUUID = CBUUID(string: BLEConstants.yLinkServiceUUID)
    private let writeCharactertisticUUID = CBUUID(string: BLEConstants.writeCharacteristicUUID)
    
    override init() {
        super.init()
        
        centralManager = CBCentralManager(
            delegate: self,
            queue: self.queue,
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true
            ])
    }
    
    deinit {
        stopScanning()
        centralManager = nil
    }
    
    func startScanning() {
        
        startScanTimer()
    }
    
    private func restartScan() {
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "RESTART REPORT SCAN")
        self.centralManager.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
    }
    
    func stopScanning() {
        
        cancelScanTimer()
        self.centralManager.stopScan()
    }
    
    private func startScanTimer() {
        
        if scanTimer != nil {
            return
        }
        
        scanTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue)
        dispatch_source_set_timer(scanTimer!, DISPATCH_TIME_NOW, UInt64(scanTimerIntervalSeconds * Double(NSEC_PER_SEC)), 0)
        dispatch_source_set_event_handler(scanTimer!) {
            self.restartScan()
        }
        dispatch_resume(scanTimer!)
    }
    
    private func cancelScanTimer() {
        if let t = scanTimer {
            dispatch_source_cancel(t)
            scanTimer = nil
        }
    }
    
    private func newOperationForYLinkUUID(uuid: CBUUID) -> YLinkReportOperation {
        
        if let operation = operationForYLinkUUID(uuid) {
            return operation
        }
        
        let operation = YLinkReportOperation(macAddress: YLink.macAddressFromAdvert(uuid))
        operations.append(operation)
        
        return operation
    }
    
    private func operationForYLinkUUID(UUIDToFind: CBUUID) -> YLinkReportOperation? {
        
        let macAddress = YLink.macAddressFromAdvert(UUIDToFind)
        for operation in operations {
            if operation.macAddress == macAddress {
                return operation
            }
        }
        return nil
    }
    
    private func operationForPeripheral(peripheralToFind: CBPeripheral) -> YLinkReportOperation? {
        
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
    
    private func writePL_GetReport(operation: YLinkReportOperation) {
        
        guard let writeChar = operation.writeCharacteristic,
            let peripheral = operation.peripheral else {
            return
        }
        
        let data = NSData(bytes: [PL_GetReport.identity] as [UInt8], length: 1)
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Writing PL_GetReport..")
        
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
    
    private func writeCL_ReportAck(operation: YLinkReportOperation, cl_reportAck: String?) {
        
        guard let writeChar = operation.writeCharacteristic,
            let peripheral = operation.peripheral,
            let cl_reportAck = cl_reportAck else {
                
                yLog(LoggerLevel.Error, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Could not write CL_ReportAck, something went missing.")
                return
        }
        
        guard let data = cl_reportAck.dataFromHexadecimalString() else {
            return
        }
        
        
        // If we are not connected with ylink, store this CL_ReportAck for later
        if peripheral.state != .Connected {
            
            if !operation.unwrittenCL_ReportAcks.contains(cl_reportAck) {
                yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Received a CL_ReportAck, but not writing because not connected. Queuing CL_ReportAck..")
                
                operation.unwrittenCL_ReportAcks.append(cl_reportAck)
            } else {
                yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Received a CL_ReportAck, but not writing because not connected. CL_ReportAck already in queue.")
            }
            return
        }
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Writing CL_ReportAck:\n\(cl_reportAck)")
        
        // Remove this CL_ReportAck from list if it exists
        if let index = operation.unwrittenCL_ReportAcks.indexOf(cl_reportAck) {
            yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Popping this CL_ReportAck from queue")
            operation.unwrittenCL_ReportAcks.removeAtIndex(index)
        }
        
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

extension YLinkReporter: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        
        print("centralManagerDidUpdateState: \(central.state.rawValue)")
        
        switch central.state {
        case CBCentralManagerState.PoweredOn:
            
            startScanning()
            
        default: break
            
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        let advData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData
        
        guard let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] else {
            return
        }
        
        for serviceUUID in serviceUUIDs {
            
            guard YLink.isYLinkAdvert(serviceUUID) && YLink.advertsHaveReport(advData) else {
                continue
            }
            
            let operation = newOperationForYLinkUUID(serviceUUID)
            operation.peripheral = peripheral
            operation.peripheral?.delegate = self
            
            let minConnectRSSI = -75
            if abs(minConnectRSSI) < abs(RSSI.integerValue) {
                yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Ignoring discovery, not in proximity. RSSI: \(RSSI.integerValue).")
                restartScan()
                return
            }
            
            if let lastTimeReceivedLP_NoReport = operation.lastTimeReceivedLP_NoReport {
                
                let secondsAgo = abs(lastTimeReceivedLP_NoReport.timeIntervalSinceNow)
                if secondsAgo < secondsToWaitSinceLastLP_NoReport {
                    yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Ignoring discovery, received LP_NoReport \(String(format: "%.2f", secondsAgo))s ago")
                    return
                }
            }
            
            // Only attempt to connect if not already connected/connecting
            if operation.peripheral?.state != .Connected && operation.peripheral?.state != .Connecting {
                yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Discovered a ylink that has reports, connecting..")
                centralManager.connectPeripheral(peripheral, options: nil)
            } else {
                yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Discovered a ylink that has reports, but already connected or connecting.")
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        
        guard let operation = operationForPeripheral(peripheral) else {
            return
        }
        
        peripheral.discoverServices([self.yLinkServiceUUID])
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Did connect to \(operation.peripheral?.name ?? "nil")")
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
        guard let operation = operationForPeripheral(peripheral) else {
            return
        }
        
        yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "[\(operation.macAddress)] Did fail to connect to \(peripheral.name ?? "nil") error: \(error).")
        
        restartScan()
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
        guard let operation = operationForPeripheral(peripheral) else {
            return
        }
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.System, message: "[\(operation.macAddress)] Did disconnect from \(peripheral.name ?? "nil") error: \(error).")
        
        // reset flags
        operation.readingFullLC_Report = false
        
        restartScan()
    }
}

extension YLinkReporter: CBPeripheralDelegate {
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        
        guard let operation = operationForPeripheral(peripheral) else {
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            if service.UUID == self.yLinkServiceUUID {
                peripheral.discoverCharacteristics([self.writeCharactertisticUUID], forService: service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        guard let operation = operationForPeripheral(peripheral) else {
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Discovered characteristics:\n\(characteristics)")
        
        for characteristic in characteristics {
            
            if characteristic.UUID == self.writeCharactertisticUUID {
                
                operation.writeCharacteristic = characteristic
                
                yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Subscribing to main write characteristic..")
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                
                // Only send PL_GetReport if no existing uploads are in process
                if operation.pendingLC_ReportUploads == 0 {
                    writePL_GetReport(operation)
                }
                
                // Write all stored CL_ReportAcks
                for cl_reportAck in operation.unwrittenCL_ReportAcks {
                    writeCL_ReportAck(operation, cl_reportAck: cl_reportAck)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        guard let operation = operationForPeripheral(peripheral) else {
            return
        }
        
        if error != nil {
            yLog(LoggerLevel.Error, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Failed to subscribe to characteristic \(characteristic.UUID)\n\nError: \(error?.localizedDescription)")
            return
        }
        
        if characteristic.UUID == operation.writeCharacteristic?.UUID && characteristic.isNotifying {
            
            yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Successfully subscribed to the yLink write characteristic")
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        guard let operation = operationForPeripheral(peripheral) else {
            return
        }
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] didUpdateValue characteristic : \(characteristic) value: \(characteristic.value)")
        
        guard let data = characteristic.value else {
            yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] No value found on the characteristic update.")
            return
        }
        
        if LP_NoReport.isThisMessageType(data) {
            
            yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Identified incoming LP_NoReport.")
            
            operation.lastTimeReceivedLP_NoReport = NSDate()
            
        } else if LC_Report.isThisMessageType(data) {
            
            yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Identified incoming LC_Report... mapping... ")
            
            guard let lc_report = LC_Report(rawData: data) else {
                yLog(LoggerLevel.Error, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] LC_Report mapping failed!")
                return
            }
            
            if operation.readingFullLC_Report == false {
                
                operation.readingFullLC_Report = true
                yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Reading full LC_Report...")
                
                if let peripheral = operation.peripheral, let writeCharacteristic = operation.writeCharacteristic {
                    peripheral.readValueForCharacteristic(writeCharacteristic)
                }
                else {
                    yLog(LoggerLevel.Warning, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] LC_Report - Missing peripheral reference to readValueForCharacteristic")
                }
                
            } else {
                
                yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Received full LC_Report message:\n\(lc_report.rawData)")
                
                operation.pendingLC_ReportUploads += 1
                
                YLink.uploadReport(operation.macAddress, lc_report: data.hexadecimalString(), success: { cl_reportAck in
                    
                    operation.pendingLC_ReportUploads -= 1
                    self.writeCL_ReportAck(operation, cl_reportAck: cl_reportAck)
                    
                }, failure: { error in
                    
                    operation.pendingLC_ReportUploads -= 1
                    yLog(LoggerLevel.Error, category: LoggerCategory.API, message: "[\(operation.macAddress)] Failed to upload LC_Report. Error:\n\(error?.localizedFailureReason)")
                    
                })
                
                operation.readingFullLC_Report = false
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        guard let operation = operationForPeripheral(peripheral) else {
            return
        }
        
        if error != nil {
            yLog(LoggerLevel.Error, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Failed to write to characteristic \(characteristic.UUID)\n\nError: \(error?.localizedDescription)")
            return
        }
        
        if characteristic.UUID == writeCharactertisticUUID {
            yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Received write confirmation from the write characteristic: \(characteristic)")
        }
    }
    
}

