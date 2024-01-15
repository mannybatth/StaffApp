//
//  MainNC.swift
//  StaffApp
//
//  Created by Manny Singh on 8/9/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit

class MainNC: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hide navigationbar shadow
        self.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationBar.shadowImage = UIImage()
        
        // default barButtonItem font
        let attributes = [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont.boldSystemFontOfSize(10)]
        UIBarButtonItem.appearance().setTitleTextAttributes(attributes, forState: UIControlState.Normal)
        
        // default back button
        let backImageInsets = UIEdgeInsetsMake(50, 20, 0, 10)
        let backImage = UIImage(named: "back_white")?.imageWithRenderingMode(.AlwaysOriginal).imageWithAlignmentRectInsets(backImageInsets)
        
        UINavigationBar.appearance().backIndicatorImage = backImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backImage
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
