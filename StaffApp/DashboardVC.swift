//
//  DashboardVC.swift
//  StaffApp
//
//  Created by Manny Singh on 8/9/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import QuartzCore
import YikesStaffEngine
import KDCircularProgress

class DashboardVC: UIViewController, GenericTabViewController {
    
    var hotel : Hotel?
    
    @IBOutlet weak var needAttentionDotImageView : UIImageView!
    @IBOutlet weak var goodStatusView : UIView!
    @IBOutlet weak var badStatusView : UIView!
    @IBOutlet weak var badStatusViewLabel : UILabel!
    @IBOutlet weak var circularProgress : KDCircularProgress!
    @IBOutlet weak var countingPercentLabel : CountingPercentLabel!
    
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var blurView : UIVisualEffectView!
    @IBOutlet weak var blurViewSpinner : UIActivityIndicatorView!
    
    var percentAnimationDuration = 1.0
    
    var totalNumOfInstalledDoors : Int {
        return (hotel?.guestRoomsInstalled ?? 0) + (hotel?.amenitiesInstalled ?? 0) +
            (hotel?.commonDoorsInstalled ?? 0) + (hotel?.elevatorsInstalled ?? 0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetUI()
        self.blurViewSpinner.color = UIColor.darkGrayColor()
    }
    
    func initForHotel(hotel: Hotel) {
        
        self.hotel = hotel
        
        setupNavigationItems()
        getHotelAnalytics()
    }
    
    func setupNavigationItems() {
        
        let refreshButton = UIBarButtonItem(image: UIImage(named: "refresh_ic"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(DashboardVC.onRefreshButtonTouched(_:)))
        refreshButton.tintColor = UIColor.whiteColor()
        self.tabBarController?.navigationItem.rightBarButtonItem = refreshButton
        
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        spacer.width = 5
        
        let logoutButton = UIBarButtonItem(title: "LOGOUT", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(DashboardVC.onLogoutButtonTouched(_:)))
        self.tabBarController?.navigationItem.leftBarButtonItems = [spacer, logoutButton]
        
        self.tabBarController?.navigationItem.hidesBackButton = true
    }
    
    func resetUI() {
        
        self.goodStatusView.hidden = true
        self.badStatusView.hidden = true
        
        self.circularProgress.angle = 0
        
        self.blurView.hidden = false
    }
    
    func updateUI() {
        
        if let doorsNeedAttention = self.hotel?.doorsNeedAttention {
            
            if doorsNeedAttention > 0 {
                self.goodStatusView.hidden = true
                self.badStatusView.hidden = false
                self.badStatusViewLabel.text = "\(doorsNeedAttention) doors need attention!"
                self.needAttentionDotImageView.image = UIImage(named: "need_attention_dot")
            } else {
                self.goodStatusView.hidden = false
                self.badStatusView.hidden = true
                self.needAttentionDotImageView.image = UIImage(named: "neutral_status_dot")
            }
            
            let fractionInGoodStatus = 1.0 - (Float(doorsNeedAttention) / Float(totalNumOfInstalledDoors))
            circularProgress.glowMode = .Reverse
            circularProgress.animateFromAngle(0.0, toAngle: Double(360*fractionInGoodStatus), duration: percentAnimationDuration) { finished in
                
            }
            
            countingPercentLabel.animatePercentLabelToValue(fractionInGoodStatus*100, duration: percentAnimationDuration)
        }
        
        if let barItem = self.tabBarController?.tabBar.items?[1] {
            
            let count = (self.hotel?.doorsWithFirmwareUpdates ?? 0) + (self.hotel?.doorsWithControlDataUpdates ?? 0)
            if count > 0 {
                barItem.badgeValue = "\(count)"
            } else {
                barItem.badgeValue = nil
            }
        }
    }
    
    func getHotelAnalytics() {
        
        self.hotel?.getHotelWithAnalytics({ hotel in
            
            self.hotel = hotel
            self.tableView.reloadData()
            self.updateUI()
            
            let animation = CATransition()
            animation.type = kCATransitionFade
            animation.duration = 0.4
            self.blurView.layer.addAnimation(animation, forKey: nil)
            
            self.blurView.hidden = true
            
        }) { error in
            
            PMProgressHUD.showErrorOnController(self, title: "Failed to load hotel analytics", description: error?.localizedFailureReason ?? "")
        }
    }
    
    func onRefreshButtonTouched(sender: UIBarButtonItem) {
        
        resetUI()
        getHotelAnalytics()
    }
    
    func onLogoutButtonTouched(sender: UIBarButtonItem) {
        
        YikesStaffEngine.sharedEngine.stopEngine(nil)
        appDelegate.goToLoginView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension DashboardVC: UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0.1
        } else {
            return 32.0
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return nil
        } else if section == 1 {
            return "\(totalNumOfInstalledDoors) installed doors"
        }
        return nil
    }
    
}

extension DashboardVC: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 4
        } else if section == 1 {
            return 4
        }
        return 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            
            if indexPath.row == 0 {
                return self.hotel?.doorsWithLowBatteries > 0 ? 44 : 0
            
            } else if indexPath.row == 1 {
                return self.hotel?.doorsWithControlDataUpdates > 0 ? 44 : 0
                
            } else if indexPath.row == 2 {
                return self.hotel?.doorsWithFirmwareUpdates > 0 ? 44 : 0
                
            } else if indexPath.row == 3 {
                return self.hotel?.doorsWithPendingReports > 0 ? 44 : 0
                
            }
            
        }
        
        return 44
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("DashboardCellOne")!
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "\(self.hotel?.doorsWithLowBatteries ?? 0) need new batteries"
                
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "\(self.hotel?.doorsWithControlDataUpdates ?? 0) need config updates"
                
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "\(self.hotel?.doorsWithFirmwareUpdates ?? 0) need firmware updates"
                
            } else if indexPath.row == 3 {
                cell.textLabel?.text = "\(self.hotel?.doorsWithPendingReports ?? 0) have pending reports"
                
            }
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("DashboardCellTwo")!
            
            if indexPath.row == 0 {
                cell.textLabel?.text = "Guest Rooms"
                cell.detailTextLabel?.text = "\(self.hotel?.guestRoomsInstalled ?? 0)"
                
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Amenities"
                cell.detailTextLabel?.text = "\(self.hotel?.amenitiesInstalled ?? 0)"
                
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Common Doors"
                cell.detailTextLabel?.text = "\(self.hotel?.commonDoorsInstalled ?? 0)"
                
            } else if indexPath.row == 3 {
                cell.textLabel?.text = "Elevators"
                cell.detailTextLabel?.text = "\(self.hotel?.elevatorsInstalled ?? 0)"
                
            }
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 0 {
            
            if indexPath.row == 0 {
                self.tabBarController?.selectedIndex = 2
                
            } else if indexPath.row == 1 || indexPath.row == 2 {
                self.tabBarController?.selectedIndex = 1
            }
        }
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
}

class CountingPercentLabel : UILabel {
    
    var timer : CADisplayLink?
    var start : Float = 0.0
    var end : Float = 0.0
    
    var progress : NSTimeInterval = 0
    var lastUpdate : NSTimeInterval = 0
    var duration : NSTimeInterval = 0
    
    var currentValue : Float {
        
        if progress >= duration {
            return end
        }
        
        let percent = Float(progress / duration)
        let update = Float(percent)
        return start + (update * (end - start));
    }
    
    func animatePercentLabelToValue(toValue: Float, duration: NSTimeInterval) {
        
        self.end = toValue
        self.progress = 0
        self.lastUpdate = NSDate.timeIntervalSinceReferenceDate()
        self.duration = duration
        
        killTimer()
        
        self.timer = CADisplayLink(target: self, selector: #selector(CountingPercentLabel.updatePrecentLabel))
        self.timer!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    func updatePrecentLabel() {
        
        let now = NSDate.timeIntervalSinceReferenceDate()
        progress = progress + (now - lastUpdate)
        lastUpdate = now
        
        if progress >= duration {
            killTimer()
            progress = duration
        }
        
        self.text = "\(Int(currentValue))%"
    }
    
    func killTimer() {
        timer?.invalidate()
        timer = nil
    }
    
}



