//
//  PMProgressHUD.swift
//  StaffApp
//
//  Created by Manny Singh on 8/12/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import PMAlertController

class PMProgressHUD {
    
    class func showSuccessOnController(parent: UIViewController, title: String, description: String? = nil, completion: (() -> Void)? = nil) {
        
        let alertVC = PMAlertController(title: title, description: description ?? "", image: UIImage(named: "small_green_check"), style: .Alert)
        
        alertVC.alertImage.contentMode = UIViewContentMode.Bottom
        alertVC.alertImageHeightConstraint.constant = 45
        
        alertVC.alertTitle.textColor = UIColor(hex6: 0x75BA20)
        
        alertVC.alertStackViewHeightConstraint.constant = 18
        alertVC.alertMaskBackground.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        
        parent.presentViewController(alertVC, animated: true, completion: nil)
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            completion?()
            alertVC.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    class func showErrorOnController(parent: UIViewController, title: String, description: String? = nil, completion: (() -> Void)? = nil) {
        
        let alertVC = PMAlertController(title: title, description: description ?? "", image: UIImage(named: "small_red_cross"), style: .Alert)
        
        alertVC.alertImage.contentMode = UIViewContentMode.Bottom
        alertVC.alertImageHeightConstraint.constant = 45
        
        alertVC.alertTitle.textColor = UIColor(hex6: 0xCF2062)
        
        alertVC.alertStackViewHeightConstraint.constant = 18
        alertVC.alertMaskBackground.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        
        parent.presentViewController(alertVC, animated: true, completion: nil)
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            completion?()
            alertVC.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    class func showProgressOnController(parent: UIViewController, title: String) -> PMAlertController {
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.WhiteLarge)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = UIColor.grayColor()
        activityIndicator.startAnimating()
        
        let alertVC = PMAlertController(title: title, description: "", image: UIImage(), style: .Alert)
        
        alertVC.alertImage.contentMode = UIViewContentMode.Bottom
        alertVC.alertImageHeightConstraint.constant = 60
        alertVC.alertImage.addSubview(activityIndicator)
        
        NSLayoutConstraint(item: alertVC.alertImage, attribute: .CenterX, relatedBy: .Equal, toItem: activityIndicator, attribute: .CenterX, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: alertVC.alertImage, attribute: .CenterY, relatedBy: .Equal, toItem: activityIndicator, attribute: .CenterY, multiplier: 1, constant: -5).active = true
        
        alertVC.alertTitle.textColor = UIColor(hex6: 0xCF2062)
        
        alertVC.alertStackViewHeightConstraint.constant = 18
        alertVC.alertMaskBackground.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
        
        alertVC.alertStackViewHeightConstraint.constant = 5
        for constraint in alertVC.alertDescription.constraints {
            if constraint.constant == 21 {
                constraint.constant = 0
            }
        }
        
        parent.presentViewController(alertVC, animated: true, completion: nil)
        
        return alertVC
    }
    
}
