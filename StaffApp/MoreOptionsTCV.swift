//
//  MoreOptionsTCV.swift
//  StaffApp
//
//  Created by Manny Singh on 8/12/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesStaffEngine

class MoreOptionsTCV: UITableViewController, GenericTabViewController {

    var hotel : Hotel!
    
    var documentController : UIDocumentInteractionController?
    
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
    
    func shareLogFile(fileInfo: LogFileInfo) {
        
        documentController = UIDocumentInteractionController(URL: fileInfo.filePathURL)
        documentController?.presentOptionsMenuFromRect(self.view.frame, inView: self.view, animated: true)
    }
    
    func exportStaffAppLogs() {
        
        let optionsAlertController = UIAlertController(title: "Export options", message: nil, preferredStyle: .ActionSheet)
        
        let fullSessionLogsAction = UIAlertAction(title: "Full Session Logs", style: .Default) { (action: UIAlertAction) -> Void in
            
            let logsAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            
            for fileInfo in YikesStaffEngine.sharedEngine.sortedLogFileInfos() {
                
                let fileAction = UIAlertAction(title: fileInfo.fileName, style: .Default) { action in
                    self.shareLogFile(fileInfo)
                }
                logsAlertController.addAction(fileAction)
                
            }
            
            logsAlertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            self.presentViewController(logsAlertController, animated: true, completion: nil)
        }
        
        optionsAlertController.addAction(fullSessionLogsAction)
        
        optionsAlertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        presentViewController(optionsAlertController, animated: true, completion: nil)
    }
    
    @IBAction func dailyNotificationsSwitchValueChanged(sender: UISwitch) {
        
        print("switch value changed")
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
        
        if let vc = segue.destinationViewController as? YLinkInstallVC {
            vc.hotel = self.hotel
        }
    }
    
}

extension MoreOptionsTCV {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.section == 1 {
            
            if indexPath.row == 1 {
                exportStaffAppLogs()
            }
        }
    }
    
}
