//
//  LoginNC.swift
//  StaffApp
//
//  Created by Manny Singh on 8/15/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit

class LoginNC: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hide navigationbar shadow
        self.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationBar.shadowImage = UIImage()
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
