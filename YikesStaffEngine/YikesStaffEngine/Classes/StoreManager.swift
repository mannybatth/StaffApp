//
//  StoreManager.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import KeychainAccess

class StoreManager {
    
    public static let sharedInstance = StoreManager()
    
    let keychain = Keychain(service: KeychainConstants.keychainAppServiceName).accessibility(Accessibility.Always)
    
    func saveCurrentUser() {
        
        if let user = SessionManager.sharedInstance.currentUser {
            CacheHelper.saveObjectToCache(user, cacheName: APIEnvironment.currentAPIEnvironment.cacheKey)
        } else {
            yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "No user found to save to cache.")
        }
    }
    
    
    func restoreCurrentUserFromCache() {
        yLog(LoggerLevel.Info, category: LoggerCategory.System, message: "Trying to restore current user from cache.")
        
        if let currentUser: User? = CacheHelper.getObjectWithCacheName(APIEnvironment.currentAPIEnvironment.cacheKey) {
            
            yLog(LoggerLevel.Info, category: LoggerCategory.System, message: "Restored SP session from cache!")
            SessionManager.sharedInstance.currentUser = currentUser
        }
        
        loadGuestAppSessionCookieFromKeychain()
    }
    
    func storeGuestAppSessionCookieToKeychain() {
        yLog(LoggerLevel.Info, category: LoggerCategory.System, message: "Storing session cookie to keychain.")
        
        let cookie = SessionManager.sharedInstance.getSessionCookie()
        
        guard let cookieProperties = cookie?.properties else {
            yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "Session cookie does not have any properties to store.")
            return
        }
        
        do {
            
            let cookiesPropertiesData = try NSJSONSerialization.dataWithJSONObject(cookieProperties, options: NSJSONWritingOptions(rawValue:0))
            
            do {
                try keychain.set(cookiesPropertiesData, key: KeychainConstants.keychainSessionTokenAccountName)
            } catch let error {
                yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "Failed to store session cookie to keychain. Error: \(error)")
            }
            
        } catch {
            yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "Failed to serialize session cookie to data. Error: \(error)")
        }
    }
    
    
    func loadGuestAppSessionCookieFromKeychain() {
        yLog(LoggerLevel.Info, category: LoggerCategory.System, message: "Loading session cookie from keychain.")
        
        let baseURL = Router.baseURLString
        
        do {
            
            guard let cookiesPropertiesData = try keychain.getData(KeychainConstants.keychainSessionTokenAccountName) else {
                yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "Cookie properties from keychain were nil.")
                return
            }
            
            do {
                
                let cookieProperties = try NSJSONSerialization.JSONObjectWithData(cookiesPropertiesData, options: NSJSONReadingOptions(rawValue: 0))
                
                if let cookieProperties = cookieProperties as? [String : AnyObject],
                    let cookie = NSHTTPCookie(properties: cookieProperties) {
                    
                    NSHTTPCookieStorage.sharedHTTPCookieStorage().setCookies([cookie], forURL: NSURL(string: baseURL), mainDocumentURL: nil)
                } else {
                    yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "Failed to type cast sessionCookie.properties.")
                }
                
            } catch let error {
                yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "Failed to serialize session cookie data from keychain. Error: \(error)")
            }
            
        } catch let error {
            yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "Failed to get session cookie data from keychain. Error: \(error)")
        }
    }
    
    
    func storeCurrentGuestAppUserEmail(email: String, password: String) -> Bool {
        yLog(LoggerLevel.Info, category: LoggerCategory.System, message: "Saving user credentials to keychains.")
        
        do {
            try keychain.set(email, key: KeychainConstants.keychainEmailAccountName)
            
            do {
                
                try keychain.set(password, key: KeychainConstants.keychainPasswordAccountName)
                return true
                
            } catch let error {
                yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "User password could not be stored in keychain. Error: \(error)")
            }
            
        } catch let error {
            yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "User email could not be stored in keychain. Error: \(error)")
        }
        
        return false
    }
    
    
    func currentGuestUsernameAndPasswordFromKeychains() -> (String, String)? {
        yLog(LoggerLevel.Info, category: LoggerCategory.System, message: "Retrieving user credentials from keychains.")
        
        do {
            
            guard let username = try keychain.getString(KeychainConstants.keychainEmailAccountName) else {
                yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "User email found in keychain was nil.")
                return nil
            }
            
            do {
                
                guard let password = try keychain.getString(KeychainConstants.keychainPasswordAccountName) else {
                    yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "User password found in keychain was nil.")
                    return nil
                }
                
                return (username, password)
                
            } catch let error {
                yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "Failed to get user password from keychain. Error: \(error)")
            }
            
        } catch let error {
            yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "Failed to get user email from keychain. Error: \(error)")
        }
        
        return nil
    }
    
    
    func removeCurrentGuestCredentialsFromKeychains() {
        
        do {
            
            try keychain.remove(KeychainConstants.keychainEmailAccountName)
            try keychain.remove(KeychainConstants.keychainPasswordAccountName)
            
        } catch let error {
            yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "Failed to remove user credentials from keychain. Error: \(error)")
        }
    }
    
    
    func removeGuestAppSessionCookieFromKeychain() {
        do {
            
            try keychain.remove(KeychainConstants.keychainSessionTokenAccountName)
            
        } catch let error {
            yLog(LoggerLevel.Error, category: LoggerCategory.System, message: "Failed to remove session cookie from keychain. Error: \(error)")
        }
    }
    
    
    func removeObjectWithCurrentCacheName() {
        CacheHelper.removeObjectWithCacheName(APIEnvironment.currentAPIEnvironment.cacheKey)
    }
    
    
    func removeGuestAppSessionCookieAndObject() {
        removeGuestAppSessionCookieFromKeychain()
        removeObjectWithCurrentCacheName()
    }
}
