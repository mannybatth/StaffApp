//
//  LoginVC.swift
//  StaffApp
//
//  Created by Manny Singh on 8/15/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesStaffEngine

class LoginVC: UIViewController {

    @IBOutlet weak var devAPIButton: APIButton!
    @IBOutlet weak var qaAPIButton: APIButton!
    @IBOutlet weak var prodAPIButton: APIButton!
    
    @IBOutlet weak var apiButtonsViewHeightConstraint : NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var onePasswordButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    
    var didSignInUsing1Password = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        prepareControlsBasedOnEmailEntered()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginVC.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginVC.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func prepareControlsBasedOnEmailEntered() {
        
        hideAllAPIButtons()
        
        let currentAPIEnv = YikesStaffEngine.sharedEngine.currentApiEnv
        
        if let email = self.emailTextField.text where AppManager.isDEVTester(email) || AppManager.isQATester(email) {
            
            if AppManager.isDEVTester(email) {
                showAllAPIButtons()
                
            } else if AppManager.isQATester(email) {
                showOnlyQaAndProdButtons()
            }
            
        } else if currentAPIEnv == .DEV {
            showAllAPIButtons()
            
        } else if currentAPIEnv == .QA {
            showOnlyQaAndProdButtons()
            
        }
        
        updateAPIButtonsState()
    }
    
    func changeAPIEnvironment(value: APIEnv, withAlert: Bool = true) {
        
        YikesStaffEngine.sharedEngine.currentApiEnv = value
        
        updateAPIButtonsState()
    }
    
    func updateAPIButtonsState() {
        
        switch YikesStaffEngine.sharedEngine.currentApiEnv {
            
        case .PROD:
            devAPIButton.active = false
            qaAPIButton.active = false
            prodAPIButton.active = true
            
        case .QA:
            devAPIButton.active = false
            qaAPIButton.active = true
            prodAPIButton.active = false
            
        case .DEV:
            devAPIButton.active = true
            qaAPIButton.active = false
            prodAPIButton.active = false
        }
    }
    
    func hideAllAPIButtons() {
        devAPIButton.hidden = true
        qaAPIButton.hidden = true
        prodAPIButton.hidden = true
        apiButtonsViewHeightConstraint.constant = 0
    }
    
    func showAllAPIButtons() {
        devAPIButton.hidden = false
        qaAPIButton.hidden = false
        prodAPIButton.hidden = false
        apiButtonsViewHeightConstraint.constant = 35
    }
    
    func showOnlyQaAndProdButtons() {
        devAPIButton.hidden = true
        qaAPIButton.hidden = false
        prodAPIButton.hidden = false
        apiButtonsViewHeightConstraint.constant = 35
    }
    
    @IBAction func devAPIButtonTouched(sender: APIButton) {
        changeAPIEnvironment(APIEnv.DEV)
    }
    
    @IBAction func qaAPIButtonTouched(sender: APIButton) {
        changeAPIEnvironment(APIEnv.QA)
    }
    
    @IBAction func prodAPIButtonTouched(sender: APIButton) {
        changeAPIEnvironment(APIEnv.PROD)
    }
    
    @IBAction func onePasswordButtonTouched(sender: UIButton) {
        
    }
    
    @IBAction func signInButtonTouched(sender: UIButton) {
        
        self.emailTextField.resignFirstResponder()
        self.passwordTextField.resignFirstResponder()
        
        guard let email = self.emailTextField.text where email.characters.count > 0 else {
            
            PMProgressHUD.showErrorOnController(self, title: "Opps", description: "Email is required") {
                self.emailTextField.becomeFirstResponder()
            }
            return
        }
        
        guard let password = self.passwordTextField.text where password.characters.count > 0 else {
            
            PMProgressHUD.showErrorOnController(self, title: "Opps", description: "Password is required") {
                self.passwordTextField.becomeFirstResponder()
            }
            return
        }
        
        // switch to PROD if QA/DEV is not allowed
        if !AppManager.isDEVTester(email) && !AppManager.isQATester(email) {
            changeAPIEnvironment(APIEnv.PROD, withAlert: false)
        }
        
        let progress = PMProgressHUD.showProgressOnController(self, title: "Signing in...")
        
        let credentials = [
            "email": email,
            "password": password
        ]
        
        YikesStaffEngine.sharedEngine.startEngine(credentials: credentials, success: { (user) in
            
            if user?.isYAdminMaster == true {
                
                progress.dismissViewControllerAnimated(true, completion: nil)
                
                self.appDelegate.setFabricUserInfo()
                self.appDelegate.goToViewAfterLogin()
                
            } else {
                
                YikesStaffEngine.sharedEngine.stopEngine(nil)
                
                progress.dismissViewControllerAnimated(true) {
                    PMProgressHUD.showErrorOnController(self, title: "Failed to login", description: "Not authorized to login.")
                }
            }
            
        }) { error in
            
            progress.dismissViewControllerAnimated(true, completion: nil)
            PMProgressHUD.showErrorOnController(self, title: "Failed to login", description: error?.localizedFailureReason ?? "")
        }
    }
    
    @IBAction func forgotPasswordButtonTouched(sender: UIButton) {
        
    }
    
    @IBAction func bgViewTapped(sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
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

extension LoginVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        if textField == self.emailTextField {
            self.passwordTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            self.signInButtonTouched(self.signInButton)
        }
        
        return true
    }
    
    @IBAction func emailTextFieldEditingChanged(sender: UITextField) {
        
        prepareControlsBasedOnEmailEntered()
        didSignInUsing1Password = false
    }
    
    @IBAction func passwordFieldEditingChanged(sender: UITextField) {
        
        didSignInUsing1Password = false
    }
    
}

// UIKeyboard notifications
extension LoginVC {
    
    func keyboardWillShow(notification: NSNotification) {
        
        let userInfo : NSDictionary = notification.userInfo!
        let keyboardFrame : NSValue = userInfo.valueForKey(UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.CGRectValue()
        let keyboardHeight = keyboardRectangle.height
        let duration = userInfo.objectForKey(UIKeyboardAnimationDurationUserInfoKey) as! NSNumber
        
        let difference = ((self.view.frame.size.height - self.scrollView.frame.size.height) - self.scrollView.frame.origin.y)
        let contentInsets = UIEdgeInsetsMake(0.0, 0.0, (keyboardHeight) - difference, 0.0);
        var contentOffset = CGPointZero
        
        let activeField : UITextField = self.emailTextField.isFirstResponder() ? self.emailTextField : self.passwordTextField
        
        var aRect = self.view.frame
        aRect.size.height -= keyboardHeight
        
        let padding = activeField.frame.size.height + 10
        
        var activePoint = activeField.frame.origin
        activePoint.y += padding
        
        if !CGRectContainsPoint(aRect, activePoint) {
            contentOffset = CGPointMake(0.0, padding);
        }
        
        UIView.animateWithDuration(duration.doubleValue) {
            self.scrollView.contentInset = contentInsets
            self.scrollView.scrollIndicatorInsets = contentInsets
            if (!CGPointEqualToPoint(contentOffset, CGPointZero)) {
                self.scrollView.setContentOffset(contentOffset, animated: false)
            }
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        let userInfo : NSDictionary = notification.userInfo!
        let duration = userInfo.objectForKey(UIKeyboardAnimationDurationUserInfoKey) as! NSNumber
        let difference = ((self.view.frame.size.height - self.scrollView.frame.size.height) + self.scrollView.frame.origin.y)
        
        UIView.animateWithDuration(duration.doubleValue) {
            self.scrollView.contentInset = UIEdgeInsetsMake(0.0, 0.0, -difference, 0.0);
            self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
        }
    }
}

@IBDesignable
class APIButton : UIButton {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable var active: Bool = false {
        didSet {
            if active == true {
                self.backgroundColor = UIColor(hex6: 0x75BA20)
                self.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            } else {
                self.backgroundColor = UIColor.whiteColor()
                self.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
            }
        }
    }
}
