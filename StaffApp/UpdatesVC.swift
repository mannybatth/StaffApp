//
//  UpdatesVC.swift
//  StaffApp
//
//  Created by Manny Singh on 8/11/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesStaffEngine

class UpdatesVC: UIViewController, GenericTabViewController {
    
    @IBOutlet weak var headerContainerView : UIView!
    @IBOutlet weak var progressBarContainerView : UIView!
    @IBOutlet weak var progressBarView : UIView!
    @IBOutlet weak var progressBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView : UITableView!
    
    @IBOutlet weak var bigCheckImageView : UIImageView!
    @IBOutlet weak var doorsUpToDateLabel : UILabel!
    
    var hotel : Hotel!
    
    var otaOperations : [OTAOperation] = []
    var controlDataOperations : [ControlDataOperation] = []
    
    var isSimulating = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        YikesStaffEngine.sharedEngine.otaUpdateDelegate = self
        
        self.progressBarContainerView.layer.cornerRadius = 7
        self.progressBarView.layer.cornerRadius = 7
        
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            isSimulating = true
            simulateOTA()
        #endif
    }
    
    func simulateOTA() {
        
        let ylinksJSON  : [[ String: AnyObject ]] = [[
            "id" : 100,
            "mac_address" : "EE609AC479FF",
            "room_number" : "ROOM A",
            "firmware" : [
                "id" : 10,
                "version" : 10450
            ],
            "new_firmware" : [
                "id" : 11,
                "version" : 10451,
                "file_location" : "https://s3.amazonaws.com/uploads.hipchat.com/99462/2487256/tHNVWxEfdQBwquP/yLink.ylapp",
                "cl_firmware_update_request" : "7901E298415002992CDBAF52EE114B70A482FF79C49A60EED4280000187500003930"
            ]
            ]]
        
        if let ylinks = [YLink](JSONArray: ylinksJSON) {
            
            var ops : [OTAOperation] = []
            for ylink in ylinks {
                ops.append(OTAOperation(ylink: ylink))
            }
            
            self.OTAUpdate(foundUpdatesForOperations: ops)
        }
    }
    
    func initForHotel(hotel: Hotel) {
        
        self.hotel = hotel
        
        setupNavigationItems()
    }
    
    func setupNavigationItems() {
        
        let refreshButton = UIBarButtonItem(image: UIImage(named: "refresh_ic"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(UpdatesVC.onRefreshButtonTouched(_:)))
        refreshButton.tintColor = UIColor.whiteColor()
        self.tabBarController?.navigationItem.rightBarButtonItem = refreshButton
        self.tabBarController?.navigationItem.leftBarButtonItems = nil
        self.tabBarController?.navigationItem.hidesBackButton = true
    }
    
    func updateUI() {
        
        if self.otaOperations.count == 0 && self.controlDataOperations.count == 0 {
            
            self.bigCheckImageView.hidden = false
            self.doorsUpToDateLabel.hidden = false
            self.headerContainerView.hidden = true
            self.tableView.hidden = true
            
        } else {
            
            self.bigCheckImageView.hidden = true
            self.doorsUpToDateLabel.hidden = true
            self.headerContainerView.hidden = false
            self.tableView.hidden = false
        }
        
    }
    
    func updateCellsForOperations(operations: [OTAOperation]) {
        
        if operations.count == 0 {
            return
        }
        
        var indexPaths : [NSIndexPath] = []
        
        for operation in operations {
            let index = self.otaOperations.indexOf{ $0.ylink == operation.ylink }
            if index != nil {
                let indexPath = NSIndexPath(forRow: index!, inSection: 0)
                indexPaths.append(indexPath)
            }
        }
        
        self.tableView.beginUpdates()
        self.tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.None)
        self.tableView.endUpdates()
    }
    
    func updateCellsForOperations(operations: [ControlDataOperation]) {
        
        if operations.count == 0 {
            return
        }
        
        var indexPaths : [NSIndexPath] = []
        
        for operation in operations {
            let index = self.controlDataOperations.indexOf{ $0.ylink == operation.ylink }
            if index != nil {
                let indexPath = NSIndexPath(forRow: index!, inSection: 0)
                indexPaths.append(indexPath)
            }
        }
        
        self.tableView.beginUpdates()
        self.tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.None)
        self.tableView.endUpdates()
    }
    
    func cellForOperation(operation:OTAOperation) -> UpdateItemCell? {
        
        let index = self.otaOperations.indexOf{ $0.ylink == operation.ylink }
        if index != nil {
            let indexPath = NSIndexPath(forRow: index!, inSection: 0)
            let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? UpdateItemCell
            return cell
        }
        return nil
    }
    
    func cellForOperation(operation: ControlDataOperation) -> UpdateItemCell? {
        
        let index = self.controlDataOperations.indexOf{ $0.ylink == operation.ylink }
        if index != nil {
            let indexPath = NSIndexPath(forRow: index!, inSection: 0)
            let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? UpdateItemCell
            return cell
        }
        return nil
    }
    
    func removeOperationFromList(operation: OTAOperation) {
        
        for (index, op) in self.otaOperations.enumerate() {
            
            if op.ylink == operation.ylink {
                
                self.tableView.beginUpdates()
                
                self.otaOperations = self.otaOperations.filter { $0 !== op }
                
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                
                self.tableView.endUpdates()
                
                updateUI()
                
                break
            }
        }
    }
    
    func removeOperationFromList(operation: ControlDataOperation) {
        
        for (index, op) in self.controlDataOperations.enumerate() {
            
            if op.ylink == operation.ylink {
                
                self.tableView.beginUpdates()
                
                self.controlDataOperations = self.controlDataOperations.filter { $0 !== op }
                
                let indexPath = NSIndexPath(forRow: index, inSection: 0)
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.None)
                
                self.tableView.endUpdates()
                
                updateUI()
                
                break
            }
        }
    }
    
    func onRefreshButtonTouched(sender: UIBarButtonItem) {
        
        print("refresh updates")
        
        YikesStaffEngine.sharedEngine.refreshUpdates()
    }
    
    @IBAction func autoUpdateButtonTouched(sender: AutoUpdateButton) {
        sender.mode = (sender.mode == UpdateMode.Manual) ? UpdateMode.Automatic : UpdateMode.Manual
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension UpdatesVC: OTAUpdateDelegate {
    
    func OTAUpdate(foundUpdatesForOperations operations: [OTAOperation]) {
        
        print("Found \(operations.count) updates.")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.otaOperations.removeAll()
            self.otaOperations = operations.sort { $0.ylink.roomNumber < $1.ylink.roomNumber }
            
            self.updateUI()
            self.tableView.reloadData()
            
            if self.isSimulating {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    for operation in operations {
                        operation.status = OTAOperation.Status.Scanning
                    }
                    self.OTAUpdate(startedScanningForYLinks: operations)
                }
            }
        }
    }
    
    func OTAUpdate(startedScanningForYLinks operations: [OTAOperation]) {
        
        print("Looking for doors: \(operations.listOfRooms())")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations(operations)
            
            if self.isSimulating {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    if let op = operations.first {
                        op.status = OTAOperation.Status.Discovered
                        self.OTAUpdate(discoveredYLinkForOperation: op)
                    }
                }
            }
        }
    }
    
    func OTAUpdate(RSSIUpdate RSSI: Int, operation: OTAOperation) {
        
        print("OTA RSSI: \(RSSI) macAddress: \(operation.ylink.macAddress)")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
            
            if self.isSimulating {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    self.OTAUpdate(verifyingOperation: operation)
                }
            }
        }
    }
    
    func OTAUpdate(discoveredYLinkForOperation operation: OTAOperation) {
        
        print("Found door \(operation.ylink.roomNumber ?? "nil")")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
            
            if self.isSimulating {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    operation.status = OTAOperation.Status.VerifyingUpdate
                    self.OTAUpdate(verifyingOperation: operation)
                }
            }
        }
    }
    func OTAUpdate(verifyingOperation operation: OTAOperation) {
        
        print("Preparing update for door \(operation.ylink.roomNumber ?? "nil")")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
            
            if self.isSimulating {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    operation.status = OTAOperation.Status.UpdateVerified
                    self.OTAUpdate(operationVerifyPassed: operation)
                }
            }
        }
    }
    
    func OTAUpdate(operationVerifyFailed operation: OTAOperation) {
        
        print("Failed update for door \(operation.ylink.roomNumber ?? "nil"). Reason: Verification Failed")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
        }
    }
    
    func OTAUpdate(operationVerifyPassed operation: OTAOperation) {
        
        print("OTA operation verified for door \(operation.ylink.roomNumber ?? "nil").")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
            
            if self.isSimulating {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    operation.status = OTAOperation.Status.DownloadingFirmware
                    self.OTAUpdate(downloadingFirmware: operation, bytesRead: 0, totalBytesRead: 0, totalBytesExpectedToRead: 29976)
                }
            }
        }
    }
    
    func OTAUpdate(downloadingFirmware operation: OTAOperation, bytesRead: Int64, totalBytesRead: Int64, totalBytesExpectedToRead: Int64) {
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
            
            if self.isSimulating {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    if totalBytesRead >= totalBytesExpectedToRead {
                        
                        operation.status = OTAOperation.Status.FirmwareDownloadComplete
                        self.OTAUpdate(firmwareDownloadComplete: operation)
                        
                        return
                    }
                    
                    let chunkSize : Int64 = totalBytesExpectedToRead / 10
                    
                    operation.status = OTAOperation.Status.DownloadingFirmware
                    self.OTAUpdate(downloadingFirmware: operation, bytesRead: chunkSize, totalBytesRead: totalBytesRead+chunkSize, totalBytesExpectedToRead: 29976)
                }
            }
        }
    }
    
    func OTAUpdate(firmwareDownloadFailed operation: OTAOperation, error: NSError) {
        
        print("Failed update for door \(operation.ylink.roomNumber ?? "nil"). Reason: Download Failed")
        
        dispatch_async(dispatch_get_main_queue()) {
            
        }
    }
    
    func OTAUpdate(firmwareDownloadComplete operation: OTAOperation) {
        
        print("Firmware download done.")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
            
            if self.isSimulating {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    operation.status = OTAOperation.Status.Connected
                    self.OTAUpdate(didConnectWithYLink: operation)
                }
            }
        }
    }
    
    func OTAUpdate(didConnectWithYLink operation: OTAOperation) {
        
        print("Starting door update for macAddress: \(operation.ylink.macAddress)...")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
            
            if self.isSimulating {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    operation.status = OTAOperation.Status.Updating
                    self.OTAUpdate(didStartUpdate: operation)
                }
            }
        }
    }
    
    func OTAUpdate(didStartUpdate operation: OTAOperation) {
        
        print("Updating door \(operation.ylink.roomNumber ?? "nil")")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
            
            if self.isSimulating {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    operation.status = OTAOperation.Status.Updating
                    self.OTAUpdate(firmwareWriteProgress: operation, bytesWritten: 0, totalBytesWritten: 0, totalBytesExpectedToWrite: 29976)
                }
            }
        }
    }
    
    func OTAUpdate(firmwareWriteProgress operation: OTAOperation, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        dispatch_async(dispatch_get_main_queue()) {
            
            if let cell = self.cellForOperation(operation) {
                cell.updateOTAProgressView()
            }
            
            if self.isSimulating {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    if totalBytesWritten >= totalBytesExpectedToWrite {
                        
                        operation.status = OTAOperation.Status.WriteComplete
                        self.OTAUpdate(firmwareWriteComplete: operation)
                        
                        return
                    }
                    
                    let chunkSize : Int64 = totalBytesExpectedToWrite / 10
                    
                    operation.OTAProgress = Float(totalBytesWritten+chunkSize) / Float(29976)
                    
                    operation.status = OTAOperation.Status.Updating
                    self.OTAUpdate(firmwareWriteProgress: operation, bytesWritten: chunkSize, totalBytesWritten: totalBytesWritten+chunkSize, totalBytesExpectedToWrite: 29976)
                }
            }
        }
    }
    
    func OTAUpdate(firmwareWriteFailed operation: OTAOperation) {
        
        print("Failed to update door \(operation.ylink.roomNumber ?? "nil"). Reason: Failed To Write")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
        }
    }
    
    func OTAUpdate(firmwareWriteComplete operation: OTAOperation) {
        
        print("Firmware write complete for \(operation.ylink.roomNumber ?? "nil")")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
            
            if self.isSimulating {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    operation.status = OTAOperation.Status.ValidatingUpdate
                    self.OTAUpdate(validatingUpdateForOperation: operation)
                }
            }
        }
    }
    
    func OTAUpdate(validatingUpdateForOperation operation: OTAOperation) {
        
        print("Verifying update for door \(operation.ylink.roomNumber ?? "nil")")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
            
            if self.isSimulating {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    operation.OTAProgress = 0
                    operation.status = OTAOperation.Status.UpToDate
                    self.OTAUpdate(firmwareUpdateConfirmed: operation)
                }
            }
        }
    }
    
    func OTAUpdate(firmwareUpdateConfirmed operation: OTAOperation) {
        
        print("Update complete for door \(operation.ylink.roomNumber ?? "nil")!")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
            
            if self.isSimulating {
                
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    self.OTAUpdate(didDisconnectFromYLink: operation)
                }
            }
        }
    }
    
    func OTAUpdate(firmwareUpdateFailed operation: OTAOperation) {
        
        print("Failed to update door \(operation.ylink.roomNumber ?? "nil"). Reason: Failed to Boot")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
        }
    }
    
    func OTAUpdate(didDisconnectFromYLink operation: OTAOperation) {
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
            
            if self.isSimulating {
                
                self.OTAUpdate(operationRemovedFromScanList: operation)
            }
        }
    }
    
    func OTAUpdate(operationRemovedFromScanList operation: OTAOperation) {
        
        print("Door \(operation.ylink.roomNumber ?? "nil") removed from otaOperations.")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.removeOperationFromList(operation)
        }
    }
    
}

extension UpdatesVC: ControlDataUpdateDelegate {
    
    func ControlDataUpdate(foundUpdatesForOperations operations: [ControlDataOperation]) {
        
        print("Found \(operations.count) configurations.")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.controlDataOperations.removeAll()
            self.controlDataOperations = operations.sort { $0.ylink.roomNumber < $1.ylink.roomNumber }
            
            self.updateUI()
            self.tableView.reloadData()
        }
    }
    
    func ControlDataUpdate(startedScanningForYLinks operations: [ControlDataOperation]) {
        
        print("Looking for doors: \(operations.listOfRooms())")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations(operations)
        }
    }
    
    func ControlDataUpdate(RSSIUpdate RSSI: Int, operation: ControlDataOperation) {
        
        print("Control Data RSSI: \(RSSI) macAddress: \(operation.ylink.macAddress)")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
        }
    }
    
    func ControlDataUpdate(discoveredYLinkForOperation operation: ControlDataOperation) {
        
        print("Found door \(operation.ylink.roomNumber ?? "nil")")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
        }
    }
    
    
    func ControlDataUpdate(verifyingOperation operation: ControlDataOperation) {
        
        print("Preparing update for door \(operation.ylink.roomNumber ?? "nil")")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
        }
    }
    
    func ControlDataUpdate(operationVerifyFailed operation: ControlDataOperation) {
        
        print("Failed update for door \(operation.ylink.roomNumber ?? "nil"). Reason: Verification Failed")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
        }
    }
    
    func ControlDataUpdate(operationVerifyPassed operation: ControlDataOperation) {
        
        print("Control Data operation verified for door \(operation.ylink.roomNumber ?? "nil").")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
        }
    }
    
    func ControlDataUpdate(didConnectWithYLink operation: ControlDataOperation) {
        
        print("Starting door control data updates...")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
        }
    }
    
    func ControlDataUpdate(didStartUpdate operation: ControlDataOperation) {
        
        print("Updating door \(operation.ylink.roomNumber ?? "nil")")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
        }
    }
    
    func ControlDataUpdate(updateWriteProgress operation: ControlDataOperation, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        // not used yet
    }
    
    func ControlDataUpdate(updateWriteComplete operation: ControlDataOperation) {
        
        print("Control data write complete for door \(operation.ylink.roomNumber ?? "nil")")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
        }
    }
    
    func ControlDataUpdate(controlDataUpToDate operation: ControlDataOperation) {
        
        print("Control data update complete for door \(operation.ylink.roomNumber ?? "nil")!")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
        }
    }
    
    func ControlDataUpdate(controlDataUpdateFailed operation: ControlDataOperation) {
        
        print("Failed to update door \(operation.ylink.roomNumber ?? "nil"). Reason: Control data update failed")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
        }
    }
    
    func ControlDataUpdate(didDisconnectFromYLink operation: ControlDataOperation) {
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.updateCellsForOperations([operation])
        }
    }
    
    func ControlDataUpdate(operationRemovedFromScanList operation: ControlDataOperation) {
        
        print("Door \(operation.ylink.roomNumber ?? "nil") removed from controlDataOperations.")
        
        dispatch_async(dispatch_get_main_queue()) {
            
            self.removeOperationFromList(operation)
        }
    }
    
}

extension UpdatesVC: UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return otaOperations.count > 0 ? 40 : 0.1
        } else if section == 1 {
            return controlDataOperations.count > 0 ? 32 : 0.1
        }
        return 32
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return otaOperations.count > 0 ? "\(otaOperations.count) firmware updates needed" : nil
        } else if section == 1 {
            return controlDataOperations.count > 0 ? "\(controlDataOperations.count) config updates needed" : nil
        }
        return nil
    }
    
}

extension UpdatesVC: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return otaOperations.count
        } else if section == 1 {
            return controlDataOperations.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("UpdateItemCell") as! UpdateItemCell
        
        if indexPath.section == 0 {
            cell.otaOperation = otaOperations[indexPath.row]
        } else if indexPath.section == 1 {
            cell.controlDataOperation = controlDataOperations[indexPath.row]
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 0 {
            
            let operation = otaOperations[indexPath.row]
            YikesStaffEngine.sharedEngine.requestUpdateForOperation(operation)
            
        } else if indexPath.section == 1 {
            
            let operation = controlDataOperations[indexPath.row]
            YikesStaffEngine.sharedEngine.requestUpdateForOperation(operation)
            
        }
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
}

@IBDesignable
class AutoUpdateButton: UIButton {
    
    var mode : UpdateMode = YikesStaffEngine.sharedEngine.updateMode {
        didSet {
            
            YikesStaffEngine.sharedEngine.updateMode = mode
            
            if mode == .Automatic {
                self.setTitle("stop auto update", forState: UIControlState.Normal)
                self.setTitleColor(UIColor(hex6: 0xCF2062), forState: UIControlState.Normal)
                self.backgroundColor = UIColor.whiteColor()
            } else {
                self.setTitle("start auto update", forState: UIControlState.Normal)
                self.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                self.backgroundColor = UIColor(hex6: 0x75BA20)
            }
        }
    }
    
    override func awakeFromNib() {
        self.mode = YikesStaffEngine.sharedEngine.updateMode
    }
    
    @IBInspectable var textAlignment: Int {
        get {
            return titleLabel!.textAlignment.rawValue
        }
        set {
            titleLabel!.textAlignment = NSTextAlignment(rawValue: newValue)!
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor {
        get {
            return UIColor(CGColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue.CGColor
        }
    }
}
