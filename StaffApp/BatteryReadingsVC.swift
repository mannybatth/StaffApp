//
//  BatteryReadingsVC.swift
//  StaffApp
//
//  Created by Manny Singh on 8/11/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesStaffEngine

class BatteryReadingsVC: UIViewController, GenericTabViewController {
    
    @IBOutlet weak var tableView : UITableView!
    @IBOutlet weak var blurView : UIVisualEffectView!
    @IBOutlet weak var blurViewSpinner : UIActivityIndicatorView!
    
    var hotel : Hotel!
    var reports : [YLink] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetUI()
        self.blurViewSpinner.color = UIColor.darkGrayColor()
    }
    
    func initForHotel(hotel: Hotel) {
        
        self.hotel = hotel
        
        setupNavigationItems()
        getHotelBattery()
    }
    
    func setupNavigationItems() {
        
        let refreshButton = UIBarButtonItem(image: UIImage(named: "refresh_ic"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(BatteryReadingsVC.onRefreshButtonTouched(_:)))
        refreshButton.tintColor = UIColor.whiteColor()
        self.tabBarController?.navigationItem.rightBarButtonItem = refreshButton
        self.tabBarController?.navigationItem.leftBarButtonItems = nil
        self.tabBarController?.navigationItem.hidesBackButton = true
    }
    
    func resetUI() {
        
        self.blurView.hidden = false
    }
    
    func updateUI() {
        
    }
    
    func getHotelBattery() {
        
        self.hotel.getHotelReports({ ylinks in
            
            self.reports = ylinks
            self.tableView.reloadData()
            self.updateUI()
            
            let animation = CATransition()
            animation.type = kCATransitionFade
            animation.duration = 0.4
            self.blurView.layer.addAnimation(animation, forKey: nil)
            
            self.blurView.hidden = true
            
        }) { error in
            
            PMProgressHUD.showErrorOnController(self, title: "Failed to load hotel batteries", description: error?.localizedFailureReason ?? "")
        }
    }
    
    func onRefreshButtonTouched(sender: UIBarButtonItem) {
        
        resetUI()
        getHotelBattery()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension BatteryReadingsVC: UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
}

extension BatteryReadingsVC: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reports.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 73
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("BatteryItemCell") as! BatteryItemCell
        
        cell.ylink = reports[indexPath.row]
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}


