//
//  HotelSelectionVC.swift
//  StaffApp
//
//  Created by Manny Singh on 8/15/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesStaffEngine

class HotelSelectionVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var hotels : [Hotel] = []
    
    var userObserver : UserObserver?
    
    deinit {
        YikesStaffEngine.sharedEngine.removeUserObserver(userObserver)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userObserver = UserObserver { [weak self] user in
            
            guard let hotels = user?.hotels else {
                return
            }
            
            self?.hotels = hotels
            self?.tableView.reloadData()
            
            // Push to dashboard if there is only one hotel
            if self?.hotels.count == 1 {
                let hotel = self?.hotels.first!
                
                let tabBarBC = self?.storyboard?.instantiateViewControllerWithIdentifier("MainTabBarController") as! MainTabBarController
                tabBarBC.hotel = hotel
                
                self?.navigationController?.pushViewController(tabBarBC, animated: false)
            }
        }
        
        YikesStaffEngine.sharedEngine.addUserObserver(userObserver)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        setupNavigationItems()
        
        YikesStaffEngine.sharedEngine.stopEngineOperations()
    }
    
    func setupNavigationItems() {
        
        self.navigationItem.rightBarButtonItem = nil
        
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FixedSpace, target: nil, action: nil)
        spacer.width = 5
        
        let logoutButton = UIBarButtonItem(title: "LOGOUT", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(HotelSelectionVC.onLogoutButtonTouched(_:)))
        self.navigationItem.leftBarButtonItems = [spacer, logoutButton]
    }
    
    func onLogoutButtonTouched(sender: UIBarButtonItem) {
        
        YikesStaffEngine.sharedEngine.stopEngine(nil)
        appDelegate.goToLoginView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if let cell = sender as? HotelSelectionItemCell,
            let mainTabBarController = segue.destinationViewController as? MainTabBarController {
            
            mainTabBarController.hotel = cell.hotel
        }
    }
    
}

extension HotelSelectionVC: UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Select a hotel"
    }
}

extension HotelSelectionVC: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.hotels.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 85
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("HotelSelectionItemCell")! as! HotelSelectionItemCell
        
        cell.hotel = self.hotels[indexPath.row]
        
        return cell
    }
    
}

