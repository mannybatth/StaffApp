//
//  UserRequests.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

extension User {
    
    class func loginWithKeychainCredentials(
        success: (user: User) -> Void,
        failure: (error: NSError?) -> Void)  {
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.System, message: "Attempting to login with saved credentials.")
        
        if let (email, password) = StoreManager.sharedInstance.currentGuestUsernameAndPasswordFromKeychains() {
            User.loginRetryingNumberOfTimes(1,
                                            email: email,
                                            password: password,
                                            success: success,
                                            failure: failure)
        }
        
    }
    
    class func loginRetryingNumberOfTimes(
        ntimes: Int,
        email: String,
        password: String,
        success: (user: User) -> Void,
        failure: (error: NSError?) -> Void) {
        
        User.login(email, password: password, success: { user in
            
            success(user: user)
            
        }) { (error) -> Void in
            
            if (ntimes > 0) {
                User.loginRetryingNumberOfTimes(ntimes-1,
                                                email: email,
                                                password: password,
                                                success: success,
                                                failure: failure)
                
                return
            }
            failure(error: error)
        }
    }
    
    class func login(
        email: String,
        password: String,
        success: (user: User) -> Void,
        failure: (error: NSError?) -> Void) {
        
        let parameters = [
            "user_name": email,
            "password": password
        ]
        
        HTTPManager.sharedManager.request(Router.Login(parameters))
            .validate()
            .responseJSON { response in
                
                switch response.result {
                case .Success(let data):
                    
                    yLog(LoggerLevel.Debug, category: LoggerCategory.System, message: "LOGIN SUCCESS")
                    
                    if let responseBody = data["response_body"],
                        userDict = responseBody?["user"] as? [String: AnyObject] {
                        
                        if let user = Mapper<User>().map(userDict) {
                            
                            if let beaconDict = responseBody?["beacon"] as? [String: AnyObject] {
                                user.beacon = Mapper<Beacon>().map(beaconDict)
                            }
                            
                            if let hotelsArray = responseBody?["hotels"] as? [[String: AnyObject]] {
                                user.hotels = Mapper<Hotel>().mapArray(hotelsArray)
                            }
                            
                            success(user: user)
                            return
                        }
                    }
                    
                    failure(error: nil)
                    
                case .Failure( _):
                    failure(error: response.result.error)
                }
        }
    }
    
    class func logout(
        success: () -> Void) {
        
        HTTPManager.sharedManager.request(Router.Logout())
            .responseJSON { response in
                success()
        }
    }
    
    class func reloginIfUserForbidden(response: NSHTTPURLResponse?, success: () -> Void, failure: () -> Void) {
        
        if let resp = response {
            if resp.statusCode == 401 || resp.statusCode == 403 {
                
                User.loginWithKeychainCredentials({ user in
                    success()
                },failure: { _ in
                    failure()
                })
                
                return
            }
        }
        
        failure()
    }
}
