//
//  HTTPManager.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import Alamofire

class HTTPManager: Manager {
    
    enum Style {
        case Verbose
        case Light
    }
    
    static var networkLogStyle: Style = .Light
    
    static let sharedManager: HTTPManager = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Manager.defaultHTTPHeaders
        
        let manager = HTTPManager(configuration: configuration)
        
        manager.delegate.dataTaskDidReceiveResponse = {(session:NSURLSession, dataTask:NSURLSessionDataTask, response:NSURLResponse) -> NSURLSessionResponseDisposition in
            NetworkLogger.logResponse(response, dataTask: dataTask)
            return NSURLSessionResponseDisposition.Allow
        }
        
        return manager
    }()
    
    override func request(URLRequest: URLRequestConvertible) -> Request {
        let request = super.request(URLRequest)
        
        NetworkLogger.logRequest(request)
        
        return request
    }
    
    func cancelAllTasks() {
        session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) in
            for dataTask in dataTasks {
                dataTask.suspend()
                dataTask.cancel()
            }
        }
    }
    
}
