//
//  HotelSelectionItemCell.swift
//  StaffApp
//
//  Created by Manny Singh on 8/15/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import UIKit
import YikesStaffEngine

class HotelSelectionItemCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel?
    @IBOutlet weak var addressLabel: UILabel?
    @IBOutlet weak var phoneNumberLabel: UILabel?
    
    var hotel : Hotel! {
        didSet {
            nameLabel?.text = hotel.name
            addressLabel?.text = hotel.address?.fullAddress ?? ""
            phoneNumberLabel?.text = hotel.contactPhone
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
}
