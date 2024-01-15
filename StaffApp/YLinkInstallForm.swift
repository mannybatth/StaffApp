//
//  YLinkInstallForm.swift
//  StaffApp
//
//  Created by Manny Singh on 8/12/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesStaffEngine

class YLinkInstallForm: UITableViewController {
    
    @IBOutlet weak var navigationBar : UINavigationBar!
    
    @IBOutlet weak var nameTextField : UITextField!
    @IBOutlet weak var serialNumberTextField : UITextField!
    @IBOutlet weak var macAddressLabel : UILabel!
    @IBOutlet weak var saveButton : UIButton!
    @IBOutlet weak var spinner : UIActivityIndicatorView!
    
    var operation : YLinkInstallOperation!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!)  {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.commonInit()
    }
    
    func commonInit() {
        self.modalPresentationStyle = .Custom
        self.transitioningDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.topItem?.title = self.operation.peripheral?.name ?? "n/a"
        
        self.view.layer.cornerRadius = 5
        self.view.layer.masksToBounds = true
        self.view.layer.shadowOffset = CGSizeMake(0, 0)
        self.view.layer.shadowRadius = 8
        self.view.layer.shadowOpacity = 0.3
        
        self.saveButton?.layer.cornerRadius = 5
        
        let attributes = [
            NSForegroundColorAttributeName: UIColor.lightGrayColor(),
            NSFontAttributeName : UIFont.systemFontOfSize(16)
        ]
        self.nameTextField.attributedPlaceholder = NSAttributedString(string: "Type a name for ylink", attributes:attributes)
        self.nameTextField.text = ""
        self.nameTextField.becomeFirstResponder()
        
        self.serialNumberTextField.attributedPlaceholder = NSAttributedString(string: "ex. YL201-0001", attributes:attributes)
        self.serialNumberTextField.text = ""
        
        self.macAddressLabel.text = self.operation.macAddress
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(YLinkInstallForm.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let userInfo : NSDictionary = notification.userInfo!
        let keyboardFrame : NSValue = userInfo.valueForKey(UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.CGRectValue()
        let keyboardHeight = keyboardRectangle.height
        
        if let pc = self.presentationController as? YLinkInstallFormPresentationController,
            let containerView = pc.containerView,
            var frame = pc.presentedView()?.frame {
            
            frame.origin.x = (containerView.frame.size.width / 2) - (frame.size.width / 2)
            frame.origin.y = ((containerView.frame.size.height - keyboardHeight) / 2) - (frame.size.height / 2)
            
            pc.presentedView()?.frame = frame
        }
    }
    
    func operationDidSucceed(operation: YLinkInstallOperation) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func operationDidFail(operation: YLinkInstallOperation, error: NSError) {
        
        PMProgressHUD.showErrorOnController(self, title: "Failed to install yLink!", description: error.localizedFailureReason ?? "no error returned")
        
        // stop spinner
        self.saveButton.setTitle("SAVE", forState: UIControlState.Normal)
        self.saveButton.enabled = true
        self.spinner.stopAnimating()
    }
    
    @IBAction func onCloseButtonTouched(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func onSaveButtonTouched(sender: UIButton) {
        
        // start spinner
        self.saveButton.setTitle("", forState: UIControlState.Normal)
        self.saveButton.enabled = false
        self.spinner.startAnimating()
        
        self.nameTextField.resignFirstResponder()
        
        self.operation.roomNumber = self.nameTextField.text
        self.operation.serialNumber = self.serialNumberTextField.text
        
        YikesStaffEngine.sharedEngine.installYLinkForOperation(self.operation)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension YLinkInstallForm: UIViewControllerTransitioningDelegate {
    
    func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController, sourceViewController source: UIViewController) -> UIPresentationController? {
        
        if presented == self {
            return YLinkInstallFormPresentationController(presentedViewController: presented, presentingViewController: presenting)
        }
        
        return nil
    }
}

class YLinkInstallFormPresentationController: UIPresentationController {
    
    lazy var dimmingView :UIView = {
        let view = UIView(frame: self.containerView!.bounds)
        view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
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
        
        // Add the dimming view and the presented view to the heirarchy
        dimmingView.frame = self.containerView!.bounds
        
        // Add a tap gesture to dismiss vc
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DropdownMenuPresentationController.handleDimmingViewTap(_:)))
        dimmingView.addGestureRecognizer(gestureRecognizer)
        
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
        
        var frame = CGRectMake(0, 0, 300, 44+(48*3)+80)
        frame.origin.x = (containerView.frame.size.width / 2) - (frame.size.width / 2)
        frame.origin.y = (containerView.frame.size.height / 2) - (frame.size.height / 2)
        
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

