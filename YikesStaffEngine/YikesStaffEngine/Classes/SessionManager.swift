//
//  SessionManager.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

class SessionManager {
    
    static let sharedInstance = SessionManager()
    
    let sessionCookieName = "session_id_ycentral"
    
    var currentUser : User? {
        
        willSet(newUser) {
            
        }
        
        didSet {
            StoreManager.sharedInstance.saveCurrentUser()
            invokeCurrentUserObservers()
        }
    }
    
    var currentUserObservers : [UserObserver?] = []
    
    init() {
        
    }
    
    func invokeCurrentUserObservers() {
        
        for observer in currentUserObservers {
            observer?.block(user: currentUser)
        }
    }
    
    func destroySession() {
        yLog(LoggerLevel.Info, category: LoggerCategory.System, message: "Destroying current user session.")
        
        currentUser = nil
        deleteAllCookies()
        
        StoreManager.sharedInstance.removeGuestAppSessionCookieAndObject()
    }
    
    func getSessionCookie() -> NSHTTPCookie? {
        
        let baseURL = Router.baseURLString
        let allCookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookiesForURL(NSURL(string: baseURL)!)
        
        for cookie : NSHTTPCookie in allCookies! {
            if cookie.name == sessionCookieName {
                return cookie
            }
        }
        
        yLog(LoggerLevel.Info, category: LoggerCategory.System, message: "Session cookie was not found in HTTPCookieStorage.")
        return nil
    }
    
    func deleteAllCookies() {
        
        let baseURL = Router.baseURLString
        let allCookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookiesForURL(NSURL(string: baseURL)!)
        
        for cookie : NSHTTPCookie in allCookies! {
            NSHTTPCookieStorage.sharedHTTPCookieStorage().deleteCookie(cookie)
        }
    }
    
}
