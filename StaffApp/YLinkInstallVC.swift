//
//  YLinkInstallVC.swift
//  StaffApp
//
//  Created by Manny Singh on 8/12/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesStaffEngine

class YLinkInstallVC: UIViewController {
    
    @IBOutlet weak var tableView : UITableView!
    
    var hotel : Hotel!
    
    var operations : [YLinkInstallOperation] = []
    var finishedOperations : [YLinkInstallOperation] = []
    
    deinit {
        YikesStaffEngine.sharedEngine.stopSearchForNewYLinks()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        YikesStaffEngine.sharedEngine.startSearchForNewYLinks(withDelegate: self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension YLinkInstallVC: YLinkInstallItemCellDelegate {
    
    func installButtonTouched(cell: YLinkInstallItemCell) {
        
        let vc = storyboard?.instantiateViewControllerWithIdentifier("YLinkInstallForm") as! YLinkInstallForm
        vc.operation = cell.operation
        self.presentViewController(vc, animated: true, completion: nil)
    }
}

extension YLinkInstallVC: YLinkInstallerDelegate {
    
    func Installer(discoveredYLinksForOperations operations: [YLinkInstallOperation]) {
        self.operations = operations
        self.tableView.reloadData()
    }
    
    func Installer(operationDidSucceed operation: YLinkInstallOperation) {
        
        if let vc = self.presentedViewController as? YLinkInstallForm {
            
            if vc.operation == operation {
                vc.operationDidSucceed(operation)
            }
        }
        
        PMProgressHUD.showSuccessOnController(self, title: "Successfully installed yLink!", description: "\(operation.roomNumber ?? operation.macAddress) installed")
        
        self.finishedOperations.append(operation)
        self.tableView.reloadData()
    }
    
    func Installer(operationDidFail operation: YLinkInstallOperation, error: NSError) {
        if let vc = self.presentedViewController as? YLinkInstallForm {
            
            if vc.operation == operation {
                vc.operationDidFail(operation, error: error)
            }
        }
    }
    
}

extension YLinkInstallVC: UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return operations.count > 0 ? 45 : 0.1
        } else if section == 1 {
            return finishedOperations.count > 0 ? 32 : 0.1
        }
        return 32
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return operations.count > 0 ? "yLinks in range" : nil
        } else if section == 1 {
            return finishedOperations.count > 0 ? "yLinks installed" : nil
        }
        return nil
    }
}

extension YLinkInstallVC: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return operations.count
        } else if section == 1 {
            return finishedOperations.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if indexPath.section == 0 {
            return 52
        }
        return 63
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("YLinkInstallItemCell")! as! YLinkInstallItemCell
            
            cell.delegate = self
            cell.operation = operations[indexPath.row]
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("InstalledYLinklItemCell")!
            
            cell.textLabel?.text = finishedOperations[indexPath.row].roomNumber ?? "n/a"
            cell.detailTextLabel?.text = finishedOperations[indexPath.row].macAddress ?? "n/a"
            cell.accessoryView = UIImageView(image: UIImage(named: "small_green_check"))
            
            return cell
            
        }
    }
    
}

