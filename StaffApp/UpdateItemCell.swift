//
//  UpdateItemCell.swift
//  StaffApp
//
//  Created by Manny Singh on 8/12/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesStaffEngine

class UpdateItemCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var statusLabel: UILabel?
    @IBOutlet weak var statusImageView: UIImageView?
    @IBOutlet weak var spinner: UIActivityIndicatorView?
    @IBOutlet weak var progressView : UIView?
    
    @IBOutlet weak var progressViewWidthConstraint : NSLayoutConstraint?
    
    var otaOperation : OTAOperation! {
        didSet {
            updateOTACell()
        }
    }
    
    var controlDataOperation : ControlDataOperation! {
        didSet {
            updateControlDataCell()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        showWarningIcon()
    }
    
    func showWarningIcon() {
        statusImageView?.hidden = false
        statusImageView?.image = UIImage(named: "warning_ic")
        
        spinner?.stopAnimating()
    }
    
    func showCheckIcon() {
        statusImageView?.hidden = false
        statusImageView?.image = UIImage(named: "check_ic")
        
        spinner?.stopAnimating()
    }
    
    func showSpinner() {
        statusImageView?.hidden = true
        if spinner?.isAnimating() == false {
            spinner?.startAnimating()
        }
    }

}

extension UpdateItemCell {
    
    func updateOTACell() {
        
        self.nameLabel?.text = otaOperation.ylink.roomNumber
        self.statusLabel?.textColor = UIColor(hex6: 0x828282)
        
        showWarningIcon()
        updateOTAProgressView()
        
        let firmware = otaOperation.ylink.firmware
        guard let newFirmware = otaOperation.ylink.newFirmware else {
            return
        }
        var version: String
        if let v = firmware?.version {
            version = String(v)
        }
        else {
            version = "Unknown"
        }
        
        guard let newVersion = newFirmware.version else {
            return
        }
        
        var RSSIText = ""
        if otaOperation.latestRSSI != 0 {
            RSSIText += "RSSI: \(otaOperation.latestRSSI)"
        }
        
        switch otaOperation.status {
        case .None:
            
            self.statusLabel?.text = "r\(version) - Needs r\(newVersion)"
            
        case .Scanning:
            
            self.statusLabel?.text = "r\(version) - Needs r\(newVersion) - Searching... \(RSSIText)"
            
        case .Discovered:
            
            self.statusLabel?.text = "r\(version) - Needs r\(newVersion) - Discovered door"
            
        case .VerifyingUpdate:
            
            showSpinner()
            
            self.statusLabel?.text = "r\(version) - Needs r\(newVersion) - Verifying update..."
            
        case .UpdateVerifyFailed:
            
            self.statusLabel?.textColor = UIColor(hex6: 0xF14359)
            self.statusLabel?.text = "r\(version) - Failed to verify update."
            
        case .UpdateVerified:
            
            showSpinner()
            
            self.statusLabel?.text = "r\(version) - Needs r\(newVersion) - Update verified."
            
        case .DownloadingFirmware:
            
            showSpinner()
            
            self.statusLabel?.text = "r\(version) - Needs r\(newVersion) - Processing..."
            
        case .FirmwareDownloadFailed:
            break
            
        case .FirmwareDownloadComplete:
            
            showSpinner()
            
            break
            
        case .Connected:
            
            showSpinner()
            
            self.statusLabel?.text = "r\(version) - Needs r\(newVersion) - Connected."
            
        case .Updating:
            
            showSpinner()
            
            self.statusLabel?.textColor = UIColor(hex6: 0xF5A623)
            self.statusLabel?.text = "r\(version) - Updating to r\(newVersion)..."
            
        case .FailedToWrite:
            
            self.statusLabel?.textColor = UIColor(hex6: 0xF14359)
            self.statusLabel?.text = "r\(version) - Failed to write firmware."
            
        case .WriteComplete:
            
            showSpinner()
            
            self.statusLabel?.textColor = UIColor(hex6: 0xF5A623)
            if let transferTime = otaOperation.transferTime() {
                let text = String(format: "Wrote v%d in %.2fs", newVersion, transferTime)
                self.statusLabel?.text = text
            }
            else {
                self.statusLabel?.text = "r\(version) - Write complete"
            }
            
        case .ValidatingUpdate:
            
            showSpinner()
            
            self.statusLabel?.textColor = UIColor(hex6: 0xF5A623)
            self.statusLabel?.text = "r\(version) - Confirming update..."
            
        case .UpdateFailed:
            
            self.statusLabel?.textColor = UIColor(hex6: 0xF14359)
            self.statusLabel?.text = "r\(version) - Update failed."
            
        case .UpToDate:
            
            showCheckIcon()
            self.statusLabel?.textColor = UIColor(hex6: 0x5F9318)
            self.statusLabel?.text = "r\(newVersion) - Up to date."
            
        case .UnknownDisconnect:
            
            self.statusLabel?.textColor = UIColor(hex6: 0xF14359)
            self.statusLabel?.text = "r\(version) - Unknown disconnect - tap to retry."
        }
    }
    
    func updateOTAProgressView() {
        
        if otaOperation.OTAProgress > 0 {
            self.progressView?.hidden = false
        } else {
            self.progressView?.hidden = true
        }
        
        let width = self.frame.size.width * CGFloat(otaOperation.OTAProgress)
        
        print("width: \(width) OTAProgress: \(otaOperation.OTAProgress)")
        
        self.progressViewWidthConstraint?.constant = width
    }
}

extension UpdateItemCell {
    
    func updateControlDataCell() {
        
        self.nameLabel?.text = controlDataOperation.ylink.roomNumber ?? controlDataOperation.ylink.macAddress
        self.statusLabel?.textColor = UIColor(hex6: 0x828282)
        
        showWarningIcon()
        updateControlDataProgressView()
        
        var RSSIText = ""
        if controlDataOperation.latestRSSI != 0 {
            RSSIText += "RSSI: \(controlDataOperation.latestRSSI)"
        }
        
        switch controlDataOperation.status {
        case .None:
            
            self.statusLabel?.text = "Waiting..."
            
        case .Scanning:
            
            self.statusLabel?.text = "Searching... \(RSSIText)"
            
        case .Discovered:
            
            self.statusLabel?.text = "Discovered door..."
            
        case .VerifyingUpdate:
            
            showSpinner()
            
            self.statusLabel?.text = "Verifying update..."
            
        case .UpdateVerifyFailed:
            
            self.statusLabel?.textColor = UIColor(hex6: 0xF14359)
            self.statusLabel?.text = "Failed to verify update."
            
        case .UpdateVerified:
            
            showSpinner()
            
            self.statusLabel?.text = "Update verified."
            
        case .Connected:
            
            showSpinner()
            
            self.statusLabel?.text = "Connected."
            
        case .Updating:
            
            showSpinner()
            
            self.statusLabel?.textColor = UIColor(hex6: 0xF5A623)
            self.statusLabel?.text = "Updating configurations..."
            
        case .WriteComplete:
            
            showSpinner()
            
            self.statusLabel?.text = "Write complete"
            
        case .UpdateFailed:
            
            self.statusLabel?.textColor = UIColor(hex6: 0xF14359)
            self.statusLabel?.text = "Update failed."
            
        case .UpToDate:
            
            showCheckIcon()
            
            self.statusLabel?.textColor = UIColor(hex6: 0x5F9318)
            self.statusLabel?.text = "Up to date."
            
        case .UnknownDisconnect:
            
            self.statusLabel?.textColor = UIColor(hex6: 0xF14359)
            self.statusLabel?.text = "Unknown disconnect - tap to retry."
        }
    }
    
    func updateControlDataProgressView() {
        
        if controlDataOperation.controlDataUpdateProgress > 0 {
            self.progressView?.hidden = false
        } else {
            self.progressView?.hidden = true
        }
        
        let width = self.frame.size.width * CGFloat(controlDataOperation.controlDataUpdateProgress)
        
        print("width: \(width) controlDataUpdateProgress: \(controlDataOperation.controlDataUpdateProgress)")
        
        self.progressViewWidthConstraint?.constant = width
    }
}
