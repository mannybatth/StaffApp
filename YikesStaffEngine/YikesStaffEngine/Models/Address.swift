//
//  Address.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

public class Address: Mappable {
    
    public var addressLine1: String?
    public var addressLine2: String?
    public var addressLine3: String?
    public var city: String?
    public var country: String?
    public var postalCode: String?
    public var stateCode: String?
    
    public var fullAddress: String? {
        let street = "\(addressLine1 ?? "") \(addressLine2 ?? "") \(addressLine3 ?? "")".stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let address = "\(street) \(city) \(country) \(stateCode) \(postalCode)"
        return address
    }
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        addressLine1    <- map["address_line_1"]
        addressLine2    <- map["address_line_2"]
        addressLine3    <- map["address_line_3"]
        city            <- map["city"]
        country         <- map["country"]
        postalCode      <- map["postal_code"]
        stateCode       <- map["state_code"]
    }
    
}
