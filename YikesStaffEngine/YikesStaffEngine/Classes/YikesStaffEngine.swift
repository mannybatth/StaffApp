//
//  YikesStaffEngine.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

public protocol StaffAccessDelegate: class {
    
}

public class UserObserver {
    
    var block: (user: User?) -> Void
    
    public init(_ block: (user: User?) -> Void) {
        self.block = block
    }
}

public class YikesStaffEngine {
    
    public static let sharedEngine = YikesStaffEngine()
    
    public var currentApiEnv: APIEnv {
        get {
            return APIEnvironment.currentAPIEnvironment
        }
        set {
            APIEnvironment.currentAPIEnvironment = newValue
        }
    }
    
    public var currentUser : User? {
        return SessionManager.sharedInstance.currentUser
    }
    
    public var otaUpdateDelegate: OTAUpdateDelegate? {
        get {
            return self.yLinkUpdater?.otaUpdateDelegate
        }
        set {
            self.yLinkUpdater?.otaUpdateDelegate = newValue
        }
    }
    
    public var controlDataUpdateDelegate: ControlDataUpdateDelegate? {
        get {
            return self.yLinkUpdater?.controlDataUpdateDelegate
        }
        set {
            self.yLinkUpdater?.controlDataUpdateDelegate = newValue
        }
    }
    
    public var updateMode : UpdateMode {
        get {
            return yLinkUpdater?.updateMode ?? .Manual
        }
        set {
            self.yLinkUpdater?.updateMode = newValue
        }
    }
    
    var yLinkReporter : YLinkReporter?
    var yLinkUpdater : YLinkUpdater?
    var yLinkInstaller : YLinkInstaller?
    
    var bundleIdentifier : String {
        let bundle = NSBundle(forClass:self.dynamicType)
        return bundle.bundleIdentifier ?? ""
    }
    
    init() {
        
        yLog(LoggerLevel.Info, category: LoggerCategory.Engine, message: "Init Staff Engine. Application state: \(UIApplication.sharedApplication().applicationState.rawValue)")
        
        if let apiEnvStringValue = NSUserDefaults.standardUserDefaults().objectForKey(APIEnvironment.key) as? String {
            self.currentApiEnv = APIEnv(rawValue: apiEnvStringValue)!
        }
        
        // restore current user information from cache
        StoreManager.sharedInstance.restoreCurrentUserFromCache()
    }
    
    public func startEngine(credentials credentials: [String: String],
                            success: ((user: User?) -> Void)?,
                            failure: ((error: NSError?) -> Void)?) {
        
        guard let email = credentials["email"],
            let password = credentials["password"] else {
                
                failure?(error: EngineError.error(code: EngineError.Code.FailedToStartEngine, failureReason: "Missing email or password."))
                return
        }
        
        User.loginRetryingNumberOfTimes(2, email: email, password: password, success: { user in
            
            SessionManager.sharedInstance.currentUser = user
            StoreManager.sharedInstance.storeCurrentGuestAppUserEmail(email, password: password)
            StoreManager.sharedInstance.storeGuestAppSessionCookieToKeychain()
            
            success?(user: user)
            
        }) { error in
            failure?(error: error)
        }
    }
    
    public func stopEngine(success: (() -> Void)?) {
        
        self.stopEngineOperations()
        
        SessionManager.sharedInstance.destroySession()
        StoreManager.sharedInstance.removeCurrentGuestCredentialsFromKeychains()
        StaffAppLogger.sharedInstance.rollLogFileNow()
        
        User.logout { }
        
        success?()
    }
    
    public func startEngineOperationsForHotel(hotel: Hotel) {
        
        if self.yLinkReporter == nil {
            self.yLinkReporter = YLinkReporter()
        }
        
        self.yLinkUpdater?.stop()
        self.yLinkUpdater = nil
        self.yLinkUpdater = YLinkUpdater(hotel: hotel)
        
        self.yLinkInstaller?.stopScanning()
        self.yLinkInstaller = nil
        self.yLinkInstaller = YLinkInstaller(hotel: hotel)
    }
    
    public func stopEngineOperations() {
        
        HTTPManager.sharedManager.cancelAllTasks()
        
        self.yLinkReporter?.stopScanning()
        self.yLinkReporter = nil
        
        self.yLinkUpdater?.stop()
        self.yLinkUpdater = nil
        
        self.yLinkInstaller?.stopScanning()
        self.yLinkInstaller = nil
    }
    
    public func refreshUpdates() {
        
        yLinkUpdater?.refresh()
    }
    
    public func sortedLogFileInfos() -> [LogFileInfo] {
        return StaffAppLogger.sharedInstance.sortedLogFileInfos()
    }
    
    public func addUserObserver(observer: UserObserver?) {
        SessionManager.sharedInstance.currentUserObservers.append(observer)
        observer?.block(user: SessionManager.sharedInstance.currentUser)
    }
    
    public func removeUserObserver(observer: UserObserver?) {
        let index = SessionManager.sharedInstance.currentUserObservers.indexOf { $0 === observer }
        if index != nil {
            SessionManager.sharedInstance.currentUserObservers.removeAtIndex(index!)
        }
    }
    
}

extension YikesStaffEngine {
    
    public func startSearchForNewYLinks(withDelegate delegate: YLinkInstallerDelegate) {
        
        yLinkInstaller?.delegate = delegate
        yLinkInstaller?.startScanning()
    }
    
    public func stopSearchForNewYLinks() {
        
        yLinkInstaller?.delegate = nil
        yLinkInstaller?.stopScanning()
    }
    
    public func installYLinkForOperation(operation: YLinkInstallOperation) {
        
        yLinkInstaller?.installYLinkForOperation(operation)
    }
    
}

extension YikesStaffEngine {
    
    public func requestUpdateForOperation(operation:OTAOperation) -> Bool {
        return self.yLinkUpdater?.requestUpdateForOperation(operation) ?? false
    }
    
    public func requestUpdateForOperation(operation:ControlDataOperation) -> Bool {
        return self.yLinkUpdater?.requestUpdateForOperation(operation) ?? false
    }
    
}
