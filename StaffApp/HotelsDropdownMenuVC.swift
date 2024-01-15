//
//  HotelsDropdownMenuVC.swift
//  StaffApp
//
//  Created by Manny Singh on 8/11/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesStaffEngine

class HotelsDropdownMenuVC: UIViewController {

    @IBOutlet weak var tableView: UITableView?
    
    var selectedHotel : Hotel!
    var hotels : [Hotel] = []
    
    var userObserver : UserObserver!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!)  {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.commonInit()
    }
    
    deinit {
        YikesStaffEngine.sharedEngine.removeUserObserver(userObserver)
    }
    
    func commonInit() {
        self.modalPresentationStyle = .Custom
        self.transitioningDelegate = self
        
        userObserver = UserObserver { [weak self] user in
            
            guard let hotels = user?.hotels else {
                return
            }
            
            self?.hotels = hotels
            self?.tableView?.reloadData()
        }
        
        YikesStaffEngine.sharedEngine.addUserObserver(userObserver)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let mainNC = self.presentingViewController as? MainNC {
            
            let height = 58 * CGFloat(self.hotels.count+1)
            let maxHeight = self.view.frame.size.height - (mainNC.navigationBar.frame.size.height + 20)
            if height >= maxHeight {
                self.tableView?.scrollEnabled = true
            } else {
                self.tableView?.scrollEnabled = false
            }
        }
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

extension HotelsDropdownMenuVC: UITableViewDelegate {

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        guard let nc = self.presentingViewController as? MainNC else {
            return
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
        
        if indexPath.row == 0 {
            // go back to hotelSelectionVC
            nc.popViewControllerAnimated(true)
            return
        }
        
        let hotel = self.hotels[indexPath.row - 1]
        let tabBarBC = storyboard?.instantiateViewControllerWithIdentifier("MainTabBarController") as! MainTabBarController
        tabBarBC.hotel = hotel
        
        // replace existing tabBarController with new one
        var controllerStack = nc.viewControllers
        controllerStack.removeLast()
        controllerStack.append(tabBarBC)
        
        nc.setViewControllers(controllerStack, animated: false)
    }
    
}

extension HotelsDropdownMenuVC: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.hotels.count + 1
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 58.0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("HotelsDropdownMenuBackCell")!
            return cell
        }
        
        let hotel = self.hotels[indexPath.row - 1]
        
        let cell = tableView.dequeueReusableCellWithIdentifier("HotelsDropdownMenuItemCell")!
        cell.textLabel?.text = hotel.name
        
        if hotel.name == selectedHotel.name {
            cell.textLabel?.textColor = UIColor(hex6: 0x75BA20)
            cell.accessoryView = UIImageView(image: UIImage(named: "green_check"))
        } else {
            cell.textLabel?.textColor = UIColor.blackColor()
            cell.accessoryView = nil
        }
        
        return cell
    }
    
}

extension HotelsDropdownMenuVC: UIViewControllerTransitioningDelegate {
    
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        
        if presented == self {
            
            let presentationController = DropdownMenuPresentationController(presentedViewController: presented, presentingViewController: presenting)
            presentationController.presentedViewHeight = 58 * CGFloat(self.hotels.count+1)
            
            return presentationController
        }
        
        return nil
    }
}

class DropdownMenuPresentationController: UIPresentationController {
    
    var presentedViewHeight : CGFloat = 0
    
    lazy var dimmingView :UIView = {
        let view = UIView(frame: self.containerView!.bounds)
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        view.alpha = 0.0
        return view
    }()
    
    override func presentationTransitionWillBegin() {
        
        guard
            let containerView = containerView,
            let presentedView = presentedView()
            else {
                return
        }
        
        var frame = self.containerView!.bounds
        if let mainNC = self.presentingViewController as? MainNC {
            let navigationBarHeight = mainNC.navigationBar.frame.size.height + 20
            frame.origin.y = frame.origin.y + navigationBarHeight
            frame.size.height = frame.size.height - navigationBarHeight
        }
        
        // Add the dimming view and the presented view to the heirarchy
        dimmingView.frame = self.containerView!.bounds
        
        // Add a tap gesture to dismiss vc
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DropdownMenuPresentationController.handleDimmingViewTap(_:)))
        dimmingView.addGestureRecognizer(gestureRecognizer)
        
        containerView.frame = frame
        containerView.addSubview(dimmingView)
        containerView.addSubview(presentedView)
        
        // Fade in the dimming view alongside the transition
        if let transitionCoordinator = self.presentingViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
                self.dimmingView.alpha = 1.0
            }, completion:{ (context: UIViewControllerTransitionCoordinatorContext!) in
                
            })
        }
    }
    
    override func presentationTransitionDidEnd(completed: Bool)  {
        // If the presentation didn't complete, remove the dimming view
        if !completed {
            self.dimmingView.removeFromSuperview()
        }
    }
    
    override func dismissalTransitionWillBegin()  {
        // Fade out the dimming view alongside the transition
        if let transitionCoordinator = self.presentingViewController.transitionCoordinator() {
            transitionCoordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
                self.dimmingView.alpha  = 0.0
                }, completion:nil)
        }
    }
    
    override func dismissalTransitionDidEnd(completed: Bool) {
        // If the dismissal completed, remove the dimming view
        if completed {
            self.dimmingView.removeFromSuperview()
        }
    }
    
    override func frameOfPresentedViewInContainerView() -> CGRect {
        
        guard
            let containerView = containerView
            else {
                return CGRect()
        }
        
        let height = presentedViewHeight < containerView.frame.size.height ? presentedViewHeight : containerView.frame.size.height
        let frame = CGRectMake(0, 0, containerView.frame.size.width, height)
        return frame
    }
    
    
    // ---- UIContentContainer protocol methods
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator transitionCoordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: transitionCoordinator)
        
        guard
            let containerView = containerView
            else {
                return
        }
        
        transitionCoordinator.animateAlongsideTransition({(context: UIViewControllerTransitionCoordinatorContext!) -> Void in
            self.dimmingView.frame = containerView.bounds
            }, completion:nil)
    }
    
    func handleDimmingViewTap(gestureRecognizer: UIGestureRecognizer) {
        self.presentedViewController.dismissViewControllerAnimated(true, completion: nil)
    }
}

