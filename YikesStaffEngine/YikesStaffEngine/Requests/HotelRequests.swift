//
//  HotelRequests.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper

extension Hotel {
    
    public func getHotelWithAnalytics(
        success: (hotel: Hotel) -> Void,
        failure: (error: NSError?) -> Void) {
        
        guard let hotelId = self.hotelId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing hotel id."))
            return
        }
        
        HTTPManager.sharedManager.request(Router.GetHotelWithAnalytics(hotelId))
            .validate()
            .responseObject(keyPath: "hotel") { (response: Response<Hotel, NSError>) -> Void in
         
                switch response.result {
                case .Success(let hotel):
                    success(hotel: hotel)
                case .Failure( _):
                    
                    User.reloginIfUserForbidden(response.response, success: {
                        self.getHotelWithAnalytics(success, failure: failure)
                    }, failure: {
                        failure(error: response.result.error)
                    })
                }
        }
        
    }
    
    public func getHotelReports(
        success: (ylinks: [YLink]) -> Void,
        failure: (error: NSError?) -> Void) {
        
        guard let hotelId = self.hotelId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing hotel id."))
            return
        }
        
        HTTPManager.sharedManager.request(Router.GetHotelReports(hotelId))
            .validate()
            .responseArray(keyPath: "ylink_reports") { (response: Response<[YLink], NSError>) -> Void in
                
                switch response.result {
                case .Success(let ylinks):
                    success(ylinks: ylinks)
                case .Failure( _):
                    
                    User.reloginIfUserForbidden(response.response, success: {
                        self.getHotelReports(success, failure: failure)
                    }, failure: {
                        failure(error: response.result.error)
                    })
                }
        }
    }
    
    func getYLink(
        yLinkId: Int,
        success: (ylink: YLink) -> Void,
        failure: (error: NSError?) -> Void) {
        
        guard let hotelId = self.hotelId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing hotel id."))
            return
        }
        
        HTTPManager.sharedManager.request(Router.GetHotelYLinkUpdateDetails(hotelId, yLinkId))
            .validate()
            .responseObject(keyPath: "response_body.door") { (response: Response<YLink, NSError>) -> Void in
                
                switch response.result {
                case .Success(let ylink):
                    success(ylink: ylink)
                case .Failure( _):
                    
                    User.reloginIfUserForbidden(response.response, success: {
                        self.getYLink(yLinkId, success: success, failure: failure)
                    }, failure: {
                        failure(error: response.result.error)
                    })
                }
        }
    }
    
    func getYLinksWithFirmwareUpdates(
        success: (ylinks: [YLink]) -> Void,
        failure: (error: NSError?) -> Void) {
        
        guard let hotelId = self.hotelId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing hotel id."))
            return
        }
        
        HTTPManager.sharedManager.request(Router.GetHotelYLinksUpdates(hotelId))
            .validate()
            .responseArray(keyPath: "response_body.doors") { (response: Response<[YLink], NSError>) -> Void in
                
                switch response.result {
                case .Success(let ylinks):
                    
                    self.ylinksWithOTAUpdates = ylinks
                    StoreManager.sharedInstance.saveCurrentUser()
                    
                    success(ylinks: ylinks)
                case .Failure( _):
                    
                    User.reloginIfUserForbidden(response.response, success: {
                        self.getYLinksWithFirmwareUpdates(success, failure: failure)
                    }, failure: {
                        failure(error: response.result.error)
                    })
                }
        }
    }
    
    func updateFirmwareStatus(
        statusCode: Int,
        timeToUpdate : Int? = nil,
        ylink : YLink,
        success: () -> Void,
        failure: (error: NSError?) -> Void) {
        
        guard let hotelId = self.hotelId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing hotel id."))
            return
        }
        
        guard let yLinkId = ylink.yLinkId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing ylink id."))
            return
        }
        
        guard let firmwareId = ylink.newFirmware?.firmwareId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing firmware id."))
            return
        }
        
        var parameters = [
            "update_status_code" : statusCode,
            "firmware_id" : firmwareId
        ]
        
        if let time = timeToUpdate {
            parameters["time_to_update"] = time
            
            yLog(LoggerLevel.Debug, category: LoggerCategory.API, message: "Updating firmware status: yLink id: \(yLinkId), firmware id: \(firmwareId), status code: \(statusCode), time to update: \(time)")
            
        } else {
            yLog(LoggerLevel.Debug, category: LoggerCategory.API, message: "Updating firmware status: yLink id: \(yLinkId), firmware id: \(firmwareId), status code: \(statusCode)")
        }
        
        HTTPManager.sharedInstance.request(Router.UpdateHotelYLink(hotelId, yLinkId, parameters))
            .validate()
            .responseJSON { response in
                
                switch response.result {
                case .Success( _):
                    
                    success()
                    
                case .Failure( _):
                    
                    User.reloginIfUserForbidden(response.response, success: {
                        self.updateFirmwareStatus(statusCode, ylink: ylink, success: success, failure: failure)
                    }, failure: {
                        failure(error: response.result.error)
                    })
                }
                
        }
    }
    
    
    func sendFirmwareUpdateCompleteRawParams(
        lc_FirmwareUpdateComplete : String,
        firmwareId: Int,
        hotelId: Int,
        yLinkId: Int,
        success: () -> Void,
        failure: (error: NSError?) -> Void) {
        
        let parameters : [String: AnyObject] = [
            "lc_firmware_update_complete" : lc_FirmwareUpdateComplete,
            "firmware_id" : firmwareId
        ]
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.API, message: "Sending firmware update complete: yLink id: \(yLinkId), firmware id: \(firmwareId), lc_FirmwareUpdateComplete: \(lc_FirmwareUpdateComplete)")
        
        HTTPManager.sharedInstance.request(Router.UpdateHotelYLink(hotelId, yLinkId, parameters))
            .validate()
            .responseJSON { response in
                
                switch response.result {
                case .Success( _):
                    
                    success()
                    
                case .Failure( _):
                    
                    User.reloginIfUserForbidden(response.response, success: {
                        self.sendFirmwareUpdateCompleteRawParams(lc_FirmwareUpdateComplete, firmwareId: firmwareId, hotelId: hotelId, yLinkId: yLinkId, success: success, failure: failure)
                    }, failure: {
                        failure(error: response.result.error)
                    })
                }
        }
    }
    
    
    func sendFirmwareUpdateComplete(
        lc_FirmwareUpdateComplete : String,
        ylink : YLink,
        success: () -> Void,
        failure: (error: NSError?) -> Void) {
        
        guard let hotelId = self.hotelId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing hotel id."))
            return
        }
        
        guard let yLinkId = ylink.yLinkId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing ylink id."))
            return
        }
        
        guard let firmwareId = ylink.newFirmware?.firmwareId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing firmware id."))
            return
        }
        
        let parameters : [String: AnyObject] = [
            "lc_firmware_update_complete" : lc_FirmwareUpdateComplete,
            "firmware_id" : firmwareId
        ]
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.API, message: "Sending firmware update complete: yLink id: \(yLinkId), firmware id: \(firmwareId), lc_FirmwareUpdateComplete: \(lc_FirmwareUpdateComplete)")
        
        HTTPManager.sharedInstance.request(Router.UpdateHotelYLink(hotelId, yLinkId, parameters))
            .validate()
            .responseJSON { response in
                
                switch response.result {
                case .Success( _):
                    
                    success()
                    
                case .Failure( _):
                    
                    User.reloginIfUserForbidden(response.response, success: {
                        self.sendFirmwareUpdateComplete(lc_FirmwareUpdateComplete, ylink: ylink, success: success, failure: failure)
                    }, failure: {
                        failure(error: response.result.error)
                    })
                }
                
        }
    }
    
}

extension Hotel {
    
    func getHotelControlDataUpdates(
        success: (ylinks: [YLink]) -> Void,
        failure: (error: NSError?) -> Void) {
        
        guard let hotelId = self.hotelId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing hotel id."))
            return
        }
        
        HTTPManager.sharedManager.request(Router.GetHotelControlDataUpdates(hotelId))
            .validate()
            .responseArray(keyPath: "response_body") { (response: Response<[YLink], NSError>) -> Void in
                
                switch response.result {
                case .Success(let ylinks):
                    
                    self.ylinksWithControlDataUpdates = ylinks
                    StoreManager.sharedInstance.saveCurrentUser()
                    
                    success(ylinks: ylinks)
                case .Failure( _):
                    
                    User.reloginIfUserForbidden(response.response, success: {
                        self.getHotelControlDataUpdates(success, failure: failure)
                    }, failure: {
                        failure(error: response.result.error)
                    })
                }
        }
    }
    
    func getYLinkControlDataUpdates(
        yLinkId: Int,
        success: (ylink: YLink) -> Void,
        failure: (error: NSError?) -> Void) {
        
        guard let hotelId = self.hotelId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing hotel id."))
            return
        }
        
        HTTPManager.sharedManager.request(Router.GetYLinkControlDataUpdates(hotelId, yLinkId))
            .validate()
            .responseObject(keyPath: "response_body") { (response: Response<YLink, NSError>) -> Void in
                
                switch response.result {
                case .Success(let ylink):
                    success(ylink: ylink)
                case .Failure( _):
                    
                    User.reloginIfUserForbidden(response.response, success: {
                        self.getYLinkControlDataUpdates(yLinkId, success: success, failure: failure)
                    }, failure: {
                        failure(error: response.result.error)
                    })
                }
        }
    }
    
    func updateYLinkRFIDControlData(
        lc_RFIDControlDataUpdateComplete : String,
        ylink : YLink,
        success: () -> Void,
        failure: (error: NSError?) -> Void) {
        
        guard let hotelId = self.hotelId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing hotel id."))
            return
        }
        
        guard let yLinkId = ylink.yLinkId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing ylink id."))
            return
        }
        
        let parameters : [String: AnyObject] = [
            "lc_rfid_control_data_update_complete" : lc_RFIDControlDataUpdateComplete
        ]
        
        HTTPManager.sharedInstance.request(Router.UpdateYLinkRFIDControlData(hotelId, yLinkId, parameters))
            .validate()
            .responseJSON { response in
                
                switch response.result {
                case .Success( _):
                    
                    success()
                    
                case .Failure( _):
                    
                    User.reloginIfUserForbidden(response.response, success: {
                        self.updateYLinkRFIDControlData(lc_RFIDControlDataUpdateComplete, ylink: ylink, success: success, failure: failure)
                    }, failure: {
                        failure(error: response.result.error)
                    })
                }
                
        }
    }
    
    func updateYLinkRFIDStatusCode(
        statusCode: Int,
        ylink : YLink,
        success: () -> Void,
        failure: (error: NSError?) -> Void) {
        
        guard let hotelId = self.hotelId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing hotel id."))
            return
        }
        
        guard let yLinkId = ylink.yLinkId else {
            failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "Missing ylink id."))
            return
        }
        
        HTTPManager.sharedInstance.request(Router.UpdateYLinkRFIDStatusCode(hotelId, yLinkId, statusCode))
            .validate()
            .responseJSON { response in
                
                switch response.result {
                case .Success( _):
                    
                    success()
                    
                case .Failure( _):
                    
                    User.reloginIfUserForbidden(response.response, success: {
                        self.updateYLinkRFIDStatusCode(statusCode, ylink: ylink, success: success, failure: failure)
                    }, failure: {
                        failure(error: response.result.error)
                    })
                }
                
        }
    }
}
