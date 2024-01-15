//
//  FirmwareFileHelper.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/16/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import Alamofire

class FirmwareFileHelper {
    
    init() {
        
    }
    
    class func firmwareDirectory() -> NSURL {
        
        let engineDirectoryURL = CacheHelper.engineCacheDirectoryURL()
        let firmwareDirectoryURL = engineDirectoryURL.URLByAppendingPathComponent("YLinkFirmware")
        
        if !firmwareDirectoryURL.checkResourceIsReachableAndReturnError(nil) {
            _ = try? NSFileManager.defaultManager().createDirectoryAtURL(firmwareDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return firmwareDirectoryURL
    }
    
    class func doesFirmwareAlreadyExist(fileLocationURL: NSURL?) -> Bool {
        
        if let fileName = fileLocationURL?.lastPathComponent {
            
            let path = firmwareDirectory().URLByAppendingPathComponent(fileName)
            if path.checkResourceIsReachableAndReturnError(nil) {
                return true
            }
        }
        
        return false
    }
    
    class func downloadFirmware(forYLink ylink: YLink, progress: ((Int64, Int64, Int64) -> Void)? = nil, success: () -> Void, failure: (NSError?) -> Void) {
        
        guard let newFirmwareLocation = ylink.newFirmware?.fileLocation,
            let fileLocationURL = NSURL(string: newFirmwareLocation),
            let firmwareFileName = fileLocationURL.lastPathComponent else {
                failure(nil)
                return
        }
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.Engine, message: "Downloading firmware for hex location: \(newFirmwareLocation)")
        
        if doesFirmwareAlreadyExist(fileLocationURL) {
            
            yLog(LoggerLevel.Debug, category: LoggerCategory.Engine, message: "File '\(firmwareFileName)' already exists. Not downloading.")
            success()
            return
        }
        
        let destination : Request.DownloadFileDestination = { (temporaryURL, response) in
            return self.firmwareDirectory().URLByAppendingPathComponent(firmwareFileName)
        }
        
        download(.GET, newFirmwareLocation, destination: destination)
            .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                
                yLog(LoggerLevel.Debug, category: LoggerCategory.Engine, message: "bytesRead: \(bytesRead) totalBytesRead: \(totalBytesRead) totalBytesExpectedToRead: \(totalBytesExpectedToRead)")
                progress?(bytesRead, totalBytesRead, totalBytesExpectedToRead)
                
            }.response { _, _, _, error in
                
                if let error = error {
                    yLog(LoggerLevel.Debug, category: LoggerCategory.Engine, message: "Download failed for '\(firmwareFileName)' with error:\n \(error)")
                    failure(error)
                } else {
                    yLog(LoggerLevel.Debug, category: LoggerCategory.Engine, message: "Downloaded '\(firmwareFileName)' successfully")
                    success()
                }
        }
    }
    
    class func firmwareData(forYLink ylink: YLink) -> NSData? {
        
        guard let newFirmwareLocation = ylink.newFirmware?.fileLocation,
            let fileLocationURL = NSURL(string: newFirmwareLocation) else {
                return nil
        }
        
        if !doesFirmwareAlreadyExist(fileLocationURL) {
            return nil
        }
        
        if let fileName = fileLocationURL.lastPathComponent {
            
            let firmwareURL = firmwareDirectory().URLByAppendingPathComponent(fileName)
            let data = NSData(contentsOfURL: firmwareURL)
            return data
        }
        
        return nil
    }
    
}
