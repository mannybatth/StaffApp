//
//  Hotel.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

public class Hotel: Mappable, Hashable, Equatable, CustomStringConvertible  {
    
    public var hotelId: Int?
    public var name: String?
    public var hotelURL: NSURL?
    public var contactPhone: String?
    public var localTimezone: NSTimeZone?
    public var maxSecondaryGuests: Int?
    public var address: Address?
    
    public var doorsNeedAttention: Int?
    public var doorsWithLowBatteries: Int?
    public var doorsWithFirmwareUpdates: Int?
    public var doorsWithControlDataUpdates: Int?
    public var doorsWithPendingReports: Int?
    public var guestRoomsInstalled: Int?
    public var amenitiesInstalled: Int?
    public var commonDoorsInstalled: Int?
    public var elevatorsInstalled: Int?
    
    public var dashboardImageURL1x: String?
    public var dashboardImageURL2x: String?
    public var dashboardImageURL3x: String?
    
    public var ylinksWithOTAUpdates : [YLink]?
    public var ylinksWithControlDataUpdates : [YLink]?
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        hotelId                         <- map["id"]
        name                            <- map["name"]
        hotelURL                        <- (map["hotel_url"], URLTransform())
        contactPhone                    <- map["contact_phone"]
        localTimezone                   <- (map["local_tz"], TimeZoneTransform())
        maxSecondaryGuests              <- map["max_secondary_guests"]
        address                         <- map["address"]
        
        doorsNeedAttention              <- map["doors_need_attention"]
        doorsWithLowBatteries           <- map["doors_with_low_batteries"]
        doorsWithFirmwareUpdates        <- map["doors_with_firmware_updates"]
        doorsWithControlDataUpdates     <- map["doors_with_control_data_updates"]
        doorsWithPendingReports         <- map["doors_with_pending_reports"]
        guestRoomsInstalled             <- map["guest_rooms_installed"]
        amenitiesInstalled              <- map["amenities_installed"]
        commonDoorsInstalled            <- map["common_doors_installed"]
        elevatorsInstalled              <- map["elevators_installed"]
        
        dashboardImageURL1x             <- map["assets.dashboard_images.1x"]
        dashboardImageURL2x             <- map["assets.dashboard_images.2x"]
        dashboardImageURL3x             <- map["assets.dashboard_images.3x"]
        
        ylinksWithOTAUpdates            <- map["ylinks_with_ota_updates"]
        ylinksWithControlDataUpdates    <- map["ylinks_with_control_data_updates"]
        
        if map.mappingType == MappingType.FromJSON {
            // Remove all non-numeric characters
            contactPhone = contactPhone?.componentsSeparatedByCharactersInSet(NSCharacterSet.alphanumericCharacterSet().invertedSet).joinWithSeparator("")
        }
    }
    
    public var description: String {
        if let jsonString = self.toJSONString(true) {
            return jsonString
        }
        return "{ hotelId: \(hotelId) }"
    }
    
    public var hashValue: Int {
        return hotelId!.hashValue
    }
}

public func == (lhs: Hotel, rhs: Hotel) -> Bool {
    return (lhs.hotelId == rhs.hotelId)
}
