//
//  YLinkUpdater.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import CoreBluetooth

public enum UpdateMode: String {
    case Manual
    case Automatic
}

class YLinkUpdater: NSObject {
    
    let queue = dispatch_queue_create("com.yikesteam.staffapp.yLinkupdater", DISPATCH_QUEUE_SERIAL)
    var centralManager : CBCentralManager!
    
    weak var otaUpdateDelegate: OTAUpdateDelegate? {
        didSet {
            otaUpdateDelegate?.OTAUpdate(foundUpdatesForOperations: otaService.operations)
        }
    }
    
    weak var controlDataUpdateDelegate: ControlDataUpdateDelegate? {
        didSet {
            controlDataUpdateDelegate?.ControlDataUpdate(foundUpdatesForOperations: controlDataService.operations)
        }
    }
    
    var updateMode : UpdateMode = .Automatic {
        didSet {
            if updateMode == .Automatic {
                self.restartScan()
            }
        }
    }
    
    var currentHotel : Hotel!
    
    private let yLinkServiceUUID = CBUUID(string: BLEConstants.yLinkServiceUUID)
    
    private var otaService : OTAUpdateService!
    private var controlDataService : ControlDataUpdateService!
    
    private var ylinksToScanFor : Set<YLink> {
        var set = Set<YLink>()
        if let ylinks = currentHotel.ylinksWithOTAUpdates?.ylinksWithNewFirmware() {
            set.unionInPlace(ylinks.map { $0 })
        }
        if let ylinks = currentHotel.ylinksWithControlDataUpdates {
            set.unionInPlace(ylinks.map { $0 })
        }
        return set
    }
    
    init(hotel: Hotel) {
        super.init()
        
        self.currentHotel = hotel
        
        otaService = OTAUpdateService(updater: self)
        controlDataService = ControlDataUpdateService(updater: self)
        
        centralManager = CBCentralManager(
            delegate: self,
            queue: self.queue,
            options: [
                CBCentralManagerOptionShowPowerAlertKey: true
            ])
    }
    
    deinit {
        stop()
        centralManager = nil
    }
    
    func start() {
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "STARTING updates for hotel: \n\(currentHotel)")
        
        findUpdatesFromServer()
    }
    
    func stop() {
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "STOPPING updates.")
        self.centralManager.stopScan()
        
        otaService.operations.endAllOperations()
        controlDataService.operations.endAllOperations()
        
        otaService.operations.removeAll()
        controlDataService.operations.removeAll()
    }
    
    func refresh() {
        
        findUpdatesFromServer()
    }
    
    func restartScan() {
        
        let ylinks = Array(ylinksToScanFor)
        
        if ylinks.count == 0 {
            self.centralManager?.stopScan()
            return
        }
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "RESTARTING UPDATE SCAN: \n\(ylinks.macAddresses()).")
        self.centralManager.scanForPeripheralsWithServices(ylinks.uuids(), options: [CBCentralManagerScanOptionAllowDuplicatesKey : false])
    }
    
    private func restartAllOperations() {
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "Restarting scan for all operations.")
        
        otaService.restartAllOperations(forCentralManager: self.centralManager)
        controlDataService.restartAllOperations(forCentralManager: self.centralManager)
        
        restartScan()
    }
    
    private func findUpdatesFromServer() {
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.API, message: "Finding updates from yCentral..")
        
        self.currentHotel.getYLinksWithFirmwareUpdates({ ylinks in
            
            if ylinks.count == 0 {
                yLog(LoggerLevel.Debug, category: LoggerCategory.API, message: "No OTA updates found.")
            }
            
            // TODO: Uncomment this when ylink is ready
            /* self.currentHotel.getHotelControlDataUpdates({ ylinks in
                
                if ylinks.count == 0 {
                    yLog(LoggerLevel.Debug, category: LoggerCategory.API, message: "No RFID updates found.")
                }*/
            
                yLog(LoggerLevel.Debug, category: LoggerCategory.API, message: "Response after finding updates:\n \(self.currentHotel)")
                
                self.restartAllOperations()
                
            /* }) { error in
                
                yLog(LoggerLevel.Error, category: LoggerCategory.API, message: "Error getting RFID updates from yCentral: \n\(error)")
            }*/
        
        }) { error in
            
            yLog(LoggerLevel.Error, category: LoggerCategory.API, message: "Error getting OTA updates from yCentral: \n\(error)")
        }
    }
    
    func requestUpdateForOperation(operation:OTAOperation) -> Bool {
        
        if operation.end == nil && operation.status != OTAOperation.Status.UpdateVerified {
            operation.userDidRequestOTAUpdate = true
            otaService.verifyUpdateIsNeeded(forOperation: operation)
            return true
        }
        else {
            return false
        }
    }
    
    func requestUpdateForOperation(operation:ControlDataOperation) -> Bool {
        
        if operation.end == nil && operation.isInProgress == false {
            operation.userDidRequestControlDataUpdate = true
            controlDataService.verifyUpdateIsNeeded(forOperation: operation)
            return true
        }
        else {
            return false
        }
    }
}


extension YLinkUpdater: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.BLE, message: "centralManagerDidUpdateState called with state \(central.state.rawValue)")
        
        switch central.state {
        case .PoweredOff:
            stop()
            
        case .PoweredOn:
            start()
            
        default: break
            
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        let advData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? NSData
        
        guard let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] else {
            return
        }
        
        for serviceUUID in serviceUUIDs {
            
            guard YLink.isYLinkAdvert(serviceUUID) else {
                continue
            }
            
            guard !YLink.advertsHaveKey(advData) else {
                yLog(LoggerLevel.Warning, category: LoggerCategory.BLE, message: "[\(peripheral.name ?? "nil")] Found a ylink that needs update, but HAS KEY flag is set.")
                return
            }
            
            if let operation = otaService.operationForYLinkUUID(serviceUUID) {
                
                peripheral.delegate = self
                otaService.didDiscoverPeripheral(peripheral, operation: operation, RSSI: RSSI)
                
            } else if let operation = controlDataService.operationForYLinkUUID(serviceUUID) {
                
                peripheral.delegate = self
                controlDataService.didDiscoverPeripheral(peripheral, operation: operation, RSSI: RSSI)
            }
            
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        
        if let operation = otaService.operationForPeripheral(peripheral) {
            
            otaService.didConnectWithPeripheralForOperation(operation)
            peripheral.discoverServices([self.yLinkServiceUUID])
            
        } else if let operation = controlDataService.operationForPeripheral(peripheral) {
            
            controlDataService.didConnectWithPeripheralForOperation(operation)
            peripheral.discoverServices([self.yLinkServiceUUID])
        }
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
        //TODO: log / show error to user
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
        if let operation = otaService.operationForPeripheral(peripheral) {
            
            otaService.didDisconnectWithPeripheralForOperation(operation, error: error)
            self.restartScan()
            
        } else if let operation = controlDataService.operationForPeripheral(peripheral) {
            
            controlDataService.didDisconnectWithPeripheralForOperation(operation, error: error)
            self.restartScan()
        }
    }
}

extension YLinkUpdater: CBPeripheralDelegate {
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        
        guard let services = peripheral.services else {
            return
        }
        
        if let operation = otaService.operationForPeripheral(peripheral) {
            
            for service in services {
                if service.UUID == self.yLinkServiceUUID {
                    peripheral.discoverCharacteristics([otaService.writeCharacteristicUUID, otaService.otaCharacteristicUUID], forService: service)
                }
            }
            
        } else if let operation = controlDataService.operationForPeripheral(peripheral) {
            
            for service in services {
                if service.UUID == self.yLinkServiceUUID {
                    peripheral.discoverCharacteristics([controlDataService.writeCharacteristicUUID], forService: service)
                }
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        if let operation = otaService.operationForPeripheral(peripheral) {
            
            otaService.didDiscoverCharacteristics(characteristics, operation: operation)
            
        } else if let operation = controlDataService.operationForPeripheral(peripheral) {
            
            controlDataService.didDiscoverCharacteristics(characteristics, operation: operation)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        if let operation = otaService.operationForPeripheral(peripheral) {
            
            otaService.didUpdateValueForCharacteristic(characteristic, operation: operation, error: error)
            
        } else if let operation = controlDataService.operationForPeripheral(peripheral) {
            
            controlDataService.didUpdateValueForCharacteristic(characteristic, operation: operation, error: error)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        if let operation = otaService.operationForPeripheral(peripheral) {
            
            otaService.didWriteValueForCharacteristic(characteristic, operation: operation, error: error)
            
        } else if let operation = controlDataService.operationForPeripheral(peripheral) {
            
            controlDataService.didWriteValueForCharacteristic(characteristic, operation: operation, error: error)
        }
    }
    
}



public func yOTALog(level: LoggerLevel = .Debug, category: LoggerCategory = .System, operation: OTAOperation, message: String, filePath: String = #file, functionName: String = #function, lineNumber: Int = #line) {
    
    var mutableMessage = message
    if let roomNumber = operation.ylink.roomNumber {
        mutableMessage = "[\(roomNumber)] " + mutableMessage
    }
    yLog(level, category: category, message: mutableMessage, filePath: filePath, functionName: functionName, lineNumber: lineNumber)
}

public func yCDLog(level: LoggerLevel = .Debug, category: LoggerCategory = .System, operation: ControlDataOperation, message: String, filePath: String = #file, functionName: String = #function, lineNumber: Int = #line) {
    
    var mutableMessage = message
    if let roomNumber = operation.ylink.roomNumber {
        mutableMessage = "[\(roomNumber)] " + mutableMessage
    }
    yLog(level, category: category, message: mutableMessage, filePath: filePath, functionName: functionName, lineNumber: lineNumber)
}

