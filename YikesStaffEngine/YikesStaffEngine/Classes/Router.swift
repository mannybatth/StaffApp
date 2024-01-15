//
//  Router.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import Alamofire

enum Router : URLRequestConvertible {
    
    static var baseURLString: String {
        return APIEnvironment.currentAPIEnvironment.baseURLString
    }
    
    case Login([String: AnyObject])
    case Logout()
    
    case UpdateYLinkEncryptionKey([String: AnyObject])
    case YLinkTimeSyncRequest(String, [String: AnyObject])
    
    case GetHotelWithAnalytics(Int)
    case GetHotelReports(Int)
    
    case GetHotelYLinksUpdates(Int)
    case GetHotelYLinkUpdateDetails(Int, Int)
    case UpdateHotelYLink(Int, Int, [String: AnyObject])
    
    case GetHotelControlDataUpdates(Int)
    case GetYLinkControlDataUpdates(Int, Int)
    case UpdateYLinkRFIDControlData(Int, Int, [String: AnyObject])
    case UpdateYLinkRFIDStatusCode(Int, Int, Int)
    
    case UploadYLinkReport([String: AnyObject])
    
    case YLinkInstall([String: AnyObject])
    
    var methodWithPath: (Alamofire.Method, String) {
        switch self {
        case .Login:
            return (.POST, "/ycentral/api/session/login?_expand=user,beacon,permission")
            
        case .Logout:
            return (.GET, "/ycentral/api/session/logout")
            
            
        case .UpdateYLinkEncryptionKey:
            return (.PUT, "/ycentral/api/hotel_equipments/encryption_key")
            
        case .YLinkTimeSyncRequest(let macAddress, _):
            return (.PUT, "/ycentral/api/ylinks/\(macAddress)/time_sync")
            
            
        case .GetHotelWithAnalytics(let hotelId):
            return (.GET, "/sp/v1/hotels/\(hotelId)?analytics=1")
            
        case .GetHotelReports(let hotelId):
            return (.GET, "/sp/v1/hotels/\(hotelId)/ylink_reports")
            
            
        case .GetHotelYLinksUpdates(let hotelId):
            return (.GET, "/ycentral/api/hotels/\(hotelId)/doors?_expand=firmware&filter=updates")
            
        case .GetHotelYLinkUpdateDetails(let hotelId, let yLinkId):
            return (.GET, "/ycentral/api/hotels/\(hotelId)/doors/\(yLinkId)?_expand=firmware")
            
        case .UpdateHotelYLink(let hotelId, let yLinkId, _):
            return (.PUT, "/ycentral/api/hotels/\(hotelId)/doors/\(yLinkId)")
            
            
        case .GetHotelControlDataUpdates(let hotelId):
            return (.GET, "/sp/v1/hotels/\(hotelId)/hotel_equipments?rfid_control_data=1")
            
        case .GetYLinkControlDataUpdates(let hotelId, let yLinkId):
            return (.GET, "/sp/v1/hotels/\(hotelId)/hotel_equipments/\(yLinkId)?rfid_control_data=1")
            
        case .UpdateYLinkRFIDControlData(let hotelId, let yLinkId, _):
            return (.PUT, "/sp/v1/hotels/\(hotelId)/hotel_equipments/\(yLinkId)?rfid_control_data=1")
            
        case .UpdateYLinkRFIDStatusCode(let hotelId, let yLinkId, let statusCode):
            return (.PUT, "/sp/v1/hotels/\(hotelId)/hotel_equipments/\(yLinkId)?update_status_code=\(statusCode)")
            
            
        case .UploadYLinkReport:
            return (.POST, "/sp/v1/ylink_reports")
            
        
        case .YLinkInstall:
            return (.POST, "/sp/v1/ylink_initialization")
        }
    }
    
    var URLRequest: NSMutableURLRequest {
        let URL = NSURL(string: Router.baseURLString)!
        let (method, path) = methodWithPath
        
        let mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: path, relativeToURL: URL)!)
        mutableURLRequest.HTTPMethod = method.rawValue
        
        mutableURLRequest.setValue(ClientInfoBuilder.sharedInstance.clientVersionInfo, forHTTPHeaderField: "Yikes-Client-Version")
        
        switch self {
        case .Login(let parameters):
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .UpdateYLinkEncryptionKey(let parameters):
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .YLinkTimeSyncRequest(_, let parameters):
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .UpdateHotelYLink(_, _, let parameters):
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .UpdateYLinkRFIDControlData(_, _, let parameters):
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .UploadYLinkReport(let parameters):
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        case .YLinkInstall(let parameters):
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: parameters).0
        default:
            return ParameterEncoding.JSON.encode(mutableURLRequest, parameters: nil).0
        }
    }
}
