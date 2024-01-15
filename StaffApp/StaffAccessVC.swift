//
//  StaffAccessVC.swift
//  StaffApp
//
//  Created by Manny Singh on 8/11/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesStaffEngine

class StaffAccessVC: UIViewController, GenericTabViewController {

    var hotel : Hotel!
    
    let amenities = [
        "Gym"
    ]
    
    let guestRooms = [
        "2001", "2002", "2003", "2004"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    func initForHotel(hotel: Hotel) {
        
        self.hotel = hotel
        
        setupNavigationItems()
    }
    
    func setupNavigationItems() {
        
        self.tabBarController?.navigationItem.rightBarButtonItem = nil
        self.tabBarController?.navigationItem.leftBarButtonItems = nil
        self.tabBarController?.navigationItem.hidesBackButton = true
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

extension StaffAccessVC: UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return amenities.count > 0 ? 40 : 0.1
        } else if section == 1 {
            return guestRooms.count > 0 ? 32 : 0.1
        }
        return 32
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return amenities.count > 0 ? "Amenities" : nil
        } else if section == 1 {
            return guestRooms.count > 0 ? "Guest Rooms" : nil
        }
        return nil
    }
}

extension StaffAccessVC: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return amenities.count
        } else if section == 1 {
            return guestRooms.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("StaffAccessItemCell")! as! StaffAccessItemCell
        
        if indexPath.section == 0 {
            cell.nameLabel?.text = amenities[indexPath.row]
        } else if indexPath.section == 1 {
            cell.nameLabel?.text = guestRooms[indexPath.row]
        }
        
        return cell
    }
    
}

