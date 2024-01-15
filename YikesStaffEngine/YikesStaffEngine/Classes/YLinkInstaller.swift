//
//  YLinkInstaller.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import CoreBluetooth

class LC_KeyInfo : Message {
    
    override class var identity : UInt8 { return 0x65 }
    
    var messageID :             UInt8?
    var messageVersion :        UInt8?
    var keyIndex :              UInt8?
    var initializationVector :  [UInt8] = []
    var payload :               [UInt8] = []
    
    var description: String {
        var desc = "Name: LC_KeyInfo"
        
        if let mid = messageID, let mvers = messageVersion, let ki = keyIndex {
            desc += "\n" + "ID: " + String(format: "%02X", mid)
            desc += "\n" + "Msg version: " + String(format: "%02X", mvers)
            desc += "\n" + "key index: " + String(format: "%02X", ki)
            desc += "\n" + "IV: " + Message.bytesToHexString(initializationVector)
            desc += "\n" + "payload: " + Message.bytesToHexString(payload)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID                   <- map[start: 0, length: 1]
        messageVersion              <- map[start: 1, length: 1]
        keyIndex                    <- map[start: 2, length: 2]
        initializationVector        <- map[start: 4, length: 16]
        payload                     <- map[toEndFrom: 20]
    }
}


class CL_KeyAccept : Message {
    
    override class var identity : UInt8 { return 0x66 }
    
    var messageID :             UInt8?
    var messageVersion :        UInt8?
    var serialNum :             UInt8?
    var initializationVector :  [UInt8] = []
    var payload :               [UInt8] = []
    
    var description: String {
        var desc = "Name: CL_KeyAccept"
        
        if let mid = messageID, let mvers = messageVersion, let sn = serialNum {
            desc += "\n" + "ID: " + String(format: "%02X", mid)
            desc += "\n" + "Msg version: " + String(format: "%02X", mvers)
            desc += "\n" + "sn: " + String(format: "%02X", sn)
            desc += "\n" + "IV: " + Message.bytesToHexString(initializationVector)
            desc += "\n" + "payload: " + Message.bytesToHexString(payload)
        }
        
        return desc
    }
    
    override func mapping(map: DataMap) {
        super.mapping(map)
        
        messageID                   <- map[start: 0, length: 1]
        messageVersion              <- map[start: 1, length: 1]
        serialNum                   <- map[start: 2, length: 8]
        initializationVector        <- map[start: 10, length: 16]
        payload                     <- map[toEndFrom: 26]
    }
}

public protocol YLinkInstallerDelegate: class {
    
    func Installer(discoveredYLinksForOperations operations: [YLinkInstallOperation])
    func Installer(operationDidSucceed operation: YLinkInstallOperation)
    func Installer(operationDidFail operation: YLinkInstallOperation, error: NSError)
}

public class YLinkInstallOperation: Hashable, Equatable {
    
    public var macAddress: String
    public var peripheral: CBPeripheral?
    public var roomNumber : String?
    public var serialNumber : String?
    
    var writeCharacteristic: CBCharacteristic?
    
    init(macAddress: String) {
        self.macAddress = macAddress
    }
    
    public var hashValue: Int {
        return macAddress.hashValue
    }
}

public func == (lhs: YLinkInstallOperation, rhs: YLinkInstallOperation) -> Bool {
    return (lhs.macAddress == rhs.macAddress)
}

class YLinkInstaller: NSObject {
    
    let queue = dispatch_queue_create("com.yikesteam.staffapp.ylinkinstaller", DISPATCH_QUEUE_SERIAL)
    var centralManager : CBCentralManager!
    
    var currentHotel : Hotel!
    
    weak var delegate : YLinkInstallerDelegate?
    
    private var scanTimer : dispatch_source_t?
    private let scanTimerIntervalSeconds = 10.0
    
    private var operations : [YLinkInstallOperation] = []
    
    private let yLinkServiceUUID = CBUUID(string: BLEConstants.yLinkServiceUUID)
    private let writeCharactertisticUUID = CBUUID(string: BLEConstants.writeCharacteristicUUID)
    
    init(hotel: Hotel) {
        super.init()
        
        self.currentHotel = hotel
        
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
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "RESTART INSTALLER SCAN")
        self.centralManager.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
    }
    
    func stopScanning() {
        
        cancelScanTimer()
        self.centralManager.stopScan()
        
        operations.removeAll()
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
    
    private func newOperationForYLinkUUID(uuid: CBUUID) -> YLinkInstallOperation {
        
        if let operation = operationForYLinkUUID(uuid) {
            return operation
        }
        
        let operation = YLinkInstallOperation(macAddress: YLink.macAddressFromAdvert(uuid))
        operations.append(operation)
        
        return operation
    }
    
    private func removeOperationFromList(operation: YLinkInstallOperation) {
        
        operations = operations.filter { $0 !== operation }
        self.restartScan()
        
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.Installer(discoveredYLinksForOperations: self.operations)
        }
    }
    
    private func operationForYLinkUUID(UUIDToFind: CBUUID) -> YLinkInstallOperation? {
        
        let macAddress = YLink.macAddressFromAdvert(UUIDToFind)
        for operation in operations {
            if operation.macAddress == macAddress {
                return operation
            }
        }
        return nil
    }
    
    private func operationForPeripheral(peripheralToFind: CBPeripheral) -> YLinkInstallOperation? {
        
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
    
    func installYLinkForOperation(operation: YLinkInstallOperation) {
        
        guard let peripheral = operation.peripheral else {
            
            yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "\(operation.macAddress): No peripheral found to connect with.")
            return
        }
        
        // Only attempt to connect if not already connected/connecting
        if operation.peripheral?.state != .Connected && operation.peripheral?.state != .Connecting {
            yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Connecting with ylink to install..")
            centralManager.connectPeripheral(peripheral, options: nil)
        } else {
            yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Already connected or connecting with ylink to install, ignoring.")
        }
    }
    
    private func writeCL_KeyAccept(operation: YLinkInstallOperation, cl_keyAccept: String?) {
        
        guard let writeChar = operation.writeCharacteristic,
            let peripheral = operation.peripheral,
            let cl_keyAccept = cl_keyAccept else {
                
                yLog(LoggerLevel.Error, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Could not write CL_KeyAccept, something went missing.")
                return
        }
        
        guard let data = cl_keyAccept.dataFromHexadecimalString() else {
            return
        }
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Writing CL_KeyAccept:\n\(cl_keyAccept)")
        
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

extension YLinkInstaller: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        
        print("centralManagerDidUpdateState: \(central.state.rawValue)")
        
        switch central.state {
        case CBCentralManagerState.PoweredOn:
            
            break;
            
        default: break
            
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        let advData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData
        
        guard let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] else {
            return
        }
        
        for serviceUUID in serviceUUIDs {
            
            guard YLink.isYLinkAdvert(serviceUUID) && YLink.advertsHaveKey(advData) else {
                continue
            }
            
            let operation = newOperationForYLinkUUID(serviceUUID)
            operation.peripheral = peripheral
            operation.peripheral?.delegate = self
            
            let minConnectRSSI = -75
            if abs(minConnectRSSI) < abs(RSSI.integerValue) {
                yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Ignoring discovery of ylink with key, not in proximity. RSSI: \(RSSI.integerValue).")
                restartScan()
                return
            }
            
            yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Discovered ylink with key IN PROXIMITY.")
            
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.Installer(discoveredYLinksForOperations: self.operations)
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
        
        restartScan()
    }
}

extension YLinkInstaller: CBPeripheralDelegate {
    
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
                
                yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Reading LC_KeyInfo...")
                peripheral.readValueForCharacteristic(characteristic)
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
        
        if LC_KeyInfo.isThisMessageType(data) {
            
            let lc_keyInfo = data.hexadecimalString()
            
            guard let roomNumber = operation.roomNumber,
                let serialNumber = operation.serialNumber else {
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.delegate?.Installer(operationDidFail: operation, error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing room number or serial number."))
                    }
                    return
            }
            
            YLink.installYLink(self.currentHotel.hotelId!,
                               roomNumber: roomNumber,
                               serialNumber: serialNumber,
                               lc_keyInfo: lc_keyInfo,
                               success: { cl_keyAccept in
                
                self.writeCL_KeyAccept(operation, cl_keyAccept: cl_keyAccept)
                                
            }, failure: { error in
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate?.Installer(operationDidFail: operation, error: error ?? EngineError.error(code: EngineError.Code.ServerRequestFailed, failureReason: "Request to install ylink failed."))
                }
            })
            
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        guard let operation = operationForPeripheral(peripheral) else {
            return
        }
        
        if error != nil {
            yLog(LoggerLevel.Error, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Failed to write to characteristic \(characteristic.UUID)\n\nError: \(error?.localizedDescription)")
            
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.Installer(operationDidFail: operation, error: error!)
            }
            
            return
        }
        
        if characteristic.UUID == writeCharactertisticUUID {
            yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "[\(operation.macAddress)] Received write confirmation from the write characteristic: \(characteristic)")
            
            self.removeOperationFromList(operation)
            
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.Installer(operationDidSucceed: operation)
            }
        }
    }
    
}

