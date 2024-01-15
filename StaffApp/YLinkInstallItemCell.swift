//
//  YLinkInstallItemCell.swift
//  StaffApp
//
//  Created by Manny Singh on 8/12/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesStaffEngine

protocol YLinkInstallItemCellDelegate: class {
    func installButtonTouched(cell: YLinkInstallItemCell)
}

class YLinkInstallItemCell: UITableViewCell {

    weak var delegate: YLinkInstallItemCellDelegate?
    
    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var installButton: UIButton?
    
    var operation : YLinkInstallOperation! {
        didSet {
            updateCell()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.installButton?.layer.cornerRadius = 5
    }
    
    @IBAction func onInstallButtonTouched(sender: UIButton) {
        delegate?.installButtonTouched(self)
    }
    
    func updateCell() {
        
        self.nameLabel?.text = operation.peripheral?.name ?? "n/a"
    }
}
