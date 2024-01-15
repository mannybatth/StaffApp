//
//  MainTabBarController.swift
//  StaffApp
//
//  Created by Manny Singh on 8/9/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesStaffEngine

protocol GenericTabViewController {
    func initForHotel(hotel: Hotel)
    func setupNavigationItems()
}

class MainTabBarController: UITabBarController {

    @IBOutlet weak var titleButton: UIButton!
    
    let mainTabBarControllerDelegate = MainTabBarControllerDelegate()
    var hotel : Hotel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = mainTabBarControllerDelegate
        
        YikesStaffEngine.sharedEngine.startEngineOperationsForHotel(hotel)
        
        // add spacing between arrow image and title
        let spacing : CGFloat = 5
        let insetAmount : CGFloat = spacing / 2
        self.titleButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
        self.titleButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: -insetAmount)
        self.titleButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: insetAmount)
        
        self.titleButton.setTitle(self.hotel.name, forState: UIControlState.Normal)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // move arrow to right of title
        self.titleButton.transform = CGAffineTransformMakeScale(-1.0, 1.0)
        self.titleButton.titleLabel?.transform = CGAffineTransformMakeScale(-1.0, 1.0)
        self.titleButton.imageView?.transform = CGAffineTransformMakeScale(-1.0, 1.0)
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        if let vc = self.selectedViewController as? GenericTabViewController {
            vc.initForHotel(self.hotel)
        }
    }
    
    override var selectedIndex: Int {
        get { return super.selectedIndex }
        set {
            super.selectedIndex = newValue
            
            if let vc = self.viewControllers?[newValue] {
                self.mainTabBarControllerDelegate.tabBarController(self, didSelectViewController: vc)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func titleButtonTouched(sender: UIButton) {
        
        if let presentedViewController = self.presentedViewController {
            presentedViewController.dismissViewControllerAnimated(true, completion: nil)
            self.titleButton.setImage(UIImage(named: "dropdown_ic"), forState: UIControlState.Normal)
            return
        }
        
        let vc = storyboard?.instantiateViewControllerWithIdentifier("HotelsDropdownMenuVC") as! HotelsDropdownMenuVC
        vc.selectedHotel = self.hotel
        self.presentViewController(vc, animated: true, completion: nil)
        self.titleButton.setImage(UIImage(named: "dropdown_inverted"), forState: UIControlState.Normal)
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

class MainTabBarControllerDelegate: NSObject, UITabBarControllerDelegate {
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        
        guard let vc = viewController as? GenericTabViewController,
            let tbc = tabBarController as? MainTabBarController else {
            return
        }
        vc.initForHotel(tbc.hotel)
    }
    
}
