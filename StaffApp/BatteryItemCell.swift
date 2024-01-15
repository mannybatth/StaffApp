//
//  BatteryItemCell.swift
//  StaffApp
//
//  Created by Manny Singh on 8/12/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesStaffEngine

class BatteryItemCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var lastReadLabel: UILabel?
    
    @IBOutlet weak var yLinkBatteryImageView: UIImageView?
    @IBOutlet weak var yLinkVoltageLabel: UILabel?
    @IBOutlet weak var noYLinkVoltageLabel: UILabel?
    
    @IBOutlet weak var lockBatteryImageView: UIImageView?
    @IBOutlet weak var lockVoltageLabel: UILabel?
    @IBOutlet weak var noLockVoltageLabel: UILabel?
    
    var ylink : YLink! {
        didSet {
            updateCell()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        noYLinkVoltageLabel?.hidden = true
        noLockVoltageLabel?.hidden = true
    }
    
    func updateCell() {
        
        self.nameLabel?.text = self.ylink.roomNumber ?? "n/a"
        
        if let yLinkLevel = ylink.yLinkBattery?.level {
            self.yLinkVoltageLabel?.text = "\(yLinkLevel.substringToIndex(yLinkLevel.startIndex.advancedBy(4)))V"
        } else {
            self.yLinkVoltageLabel?.text = "--"
        }
        
        if let strength = self.ylink.yLinkBattery?.strength {
            
            switch strength {
            case .strong:
                yLinkBatteryImageView?.image = UIImage(named: "battery_full")
                yLinkVoltageLabel?.textColor = UIColor(hex6: 0x75BA20)
                
            case .ok:
                yLinkBatteryImageView?.image = UIImage(named: "battery_full")
                yLinkVoltageLabel?.textColor = UIColor(hex6: 0x75BA20)
                
            case .weak:
                yLinkBatteryImageView?.image = UIImage(named: "battery_half")
                yLinkVoltageLabel?.textColor = UIColor(hex6: 0xFF9600)
                
            case .danger:
                yLinkBatteryImageView?.image = UIImage(named: "battery_low")
                yLinkVoltageLabel?.textColor = UIColor(hex6: 0xCF2062)
                
            }
        }
        
        if let lockLevel = ylink.lockBattery?.level {
            self.lockVoltageLabel?.text = "\(lockLevel.substringToIndex(lockLevel.startIndex.advancedBy(4)))V"
        } else {
            self.lockVoltageLabel?.text = "--"
        }
        
        var reportDateToShow : NSDate?
        
        if let yLinkBatteryReportedOn = ylink.yLinkBattery?.reportedOn {
            
            if let lockBatteryReportedOn = ylink.lockBattery?.reportedOn {
                
                if yLinkBatteryReportedOn.compare(lockBatteryReportedOn) == NSComparisonResult.OrderedDescending {
                    reportDateToShow = yLinkBatteryReportedOn
                } else {
                    reportDateToShow = lockBatteryReportedOn
                }
                
            } else {
                reportDateToShow = yLinkBatteryReportedOn
            }
            
        } else {
            
            if let lockBatteryReportedOn = ylink.lockBattery?.reportedOn {
                reportDateToShow = lockBatteryReportedOn
            }
        }
        
        if let lastReportDate = reportDateToShow {
            self.lastReadLabel?.text = "Last read: \(timeAgoSinceDate(lastReportDate))"
        } else {
            self.lastReadLabel?.text = "Last read: never"
        }
    }
    
    func timeAgoSinceDate(date: NSDate) -> String {
        
        let timeSinceDate = NSDate().timeIntervalSinceDate(date)
        
        let daysSinceDate = Int(timeSinceDate / (24 * 60 * 60))
        
        switch daysSinceDate {
        case 1: return "1 day ago"
        case 0:
            
            let hoursSinceDate = Int(timeSinceDate / (60 * 60))
            switch hoursSinceDate {
            case 1: return "1 hour ago"
            case 0:
                
                let minutesSinceDate = Int(timeSinceDate / 60)
                switch minutesSinceDate {
                case 1: return "1 min ago"
                case 0:
                    
                    let secondsSinceDate = Int(timeSinceDate)
                    
                    if secondsSinceDate < 30 {
                        return "just now"
                    }
                    
                    return "\(secondsSinceDate) secs ago"
                    
                default: return "\(minutesSinceDate) mins ago"
                }
                
            default: return "\(hoursSinceDate) hours ago"
            }
            
        default: return "\(daysSinceDate) days ago"
        }
    }
    
}
