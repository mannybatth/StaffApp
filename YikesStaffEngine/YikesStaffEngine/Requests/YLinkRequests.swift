//
//  YLinkRequests.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

extension YLink {
    
    class func uploadReport(
        macAddress : String,
        lc_report : String,
        success: (cl_reportAck: String) -> Void,
        failure: (error: NSError?) -> Void) {
        
        let parameters : [String: AnyObject] = [
            "mac_address" : macAddress,
            "lc_report" : lc_report
        ]
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.API, message: "[\(macAddress)] Uploading LC_Report to server.. \n\(parameters)")
        
        HTTPManager.sharedManager.request(Router.UploadYLinkReport(parameters))
            .validate()
            .responseJSON { response in
                
                switch response.result {
                case .Success(let data):
                    
                    if let cl_reportAck = data["cl_report_ack"] as? String {
                        success(cl_reportAck: cl_reportAck)
                        return
                    }
                    
                    failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "No CL_ReportAck returned from server"))
                    
                case .Failure( _):
                    
                    User.reloginIfUserForbidden(response.response, success: {
                        self.uploadReport(macAddress, lc_report: lc_report, success: success, failure: failure)
                    }, failure: {
                        failure(error: response.result.error)
                    })
                }
        }
    }
    
    class func installYLink(
        hotelId: Int,
        roomNumber: String,
        serialNumber: String,
        lc_keyInfo: String,
        success: (cl_keyAccept: String?) -> Void,
        failure: (error: NSError?) -> Void) {
        
        let parameters : [String: AnyObject] = [
            "hotel_id": hotelId,
            "room_number": roomNumber,
            "serial_number": serialNumber,
            "lc_key_info": lc_keyInfo
        ]
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.API, message: "Installing ylink with parameters: \n\(parameters)")
        
        HTTPManager.sharedInstance.request(Router.YLinkInstall(parameters))
            .validate()
            .responseJSON { response in
                
                switch response.result {
                case .Success(let data):
                    
                    if let cl_keyAccept = data["cl_key_accept"] as? String {
                        success(cl_keyAccept: cl_keyAccept)
                        return
                    }
                    
                    failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "No CL_KeyAccept returned from server"))
                    
                case .Failure( _):
                    
                    User.reloginIfUserForbidden(response.response, success: {
                        self.installYLink(hotelId, roomNumber: roomNumber, serialNumber: serialNumber, lc_keyInfo: lc_keyInfo, success: success, failure: failure)
                    }, failure: {
                        failure(error: response.result.error)
                    })
                }
            }
    }
    
    func sendTimeSyncRequest(
        lc_timeSync: String,
        success: (cl_timeSync: String) -> Void,
        failure: (error: NSError?) -> Void) {
        
        let parameters = [
            "lc_time_sync": lc_timeSync
        ]
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.API, message: "sendTimeSyncRequest PUT parameters are:\n\(parameters)")
        
        HTTPManager.sharedInstance.request(Router.YLinkTimeSyncRequest(self.macAddress, parameters))
            .validate()
            .responseJSON { response in
                
                switch response.result {
                case .Success(let data):
                    
                    if let responseBody = data["response_body"],
                        let cl_timeSync = responseBody?["cl_time_sync"] as? String {
                        
                        success(cl_timeSync: cl_timeSync)
                        return
                    }
                    
                    failure(error: EngineError.error(code: EngineError.Code.MissingInputOutput, failureReason: "No CL_TimeSync returned from server"))
                    
                case .Failure( _):
                    
                    User.reloginIfUserForbidden(response.response, success: {
                        self.sendTimeSyncRequest(lc_timeSync, success: success, failure: failure)
                    }, failure: {
                        failure(error: response.result.error)
                    })
                }
                
        }
        
    }
}

