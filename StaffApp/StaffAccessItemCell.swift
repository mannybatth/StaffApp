//
//  StaffAccessItemCell.swift
//  StaffApp
//
//  Created by Manny Singh on 8/12/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit

class StaffAccessItemCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var unlockButton: UIButton?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.unlockButton?.layer.cornerRadius = 5
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
