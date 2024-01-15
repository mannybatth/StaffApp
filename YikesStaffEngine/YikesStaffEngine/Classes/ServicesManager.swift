//
//  ServicesManager.swift
//  YikesEngine
//
//  Created by Manny Singh on 11/30/15.
//  Copyright © 2015 yikes. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire

class ServicesManager: NSObject {
    
    static let sharedInstance = ServicesManager()
    
    var observers : [Observer] = []
    
    var reachability: NetworkReachabilityManager!
    
    override init() {
        super.init()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(ServicesManager.backgroundRefreshStatusDidChange(_:)),
            name: UIApplicationBackgroundRefreshStatusDidChangeNotification,
            object: nil)
        
        self.startReachabilityNotifier()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationBackgroundRefreshStatusDidChangeNotification, object: nil)
        self.stopReachabilityNotifier()
    }
    
    var missingServices : Set<ServiceType> {
        
        var missingServices = Set<ServiceType>()
        
        if !self.isReachable() {
            missingServices.insert(ServiceType.InternetConnectionService)
        }
        
        if !self.areLocationServicesEnabled() {
            missingServices.insert(ServiceType.LocationService)
        }
        
        if !self.arePushNotificationsEnabled() {
            missingServices.insert(ServiceType.PushNotificationService)
        }
        
        if !self.isBackgroundRefreshEnabled() {
            missingServices.insert(ServiceType.BackgroundAppRefreshService)
        }
        
        if !self.isBluetoothEnabled() {
            missingServices.insert(ServiceType.BluetoothService)
        }
        
        if (missingServices.count > 0) {
            yLog(LoggerLevel.Warning, category: LoggerCategory.Service, message: "Missing services: \(missingServices)")
        }
        else {
            yLog(.Info, category: .Service, message: "No missing services")
        }
        
        return missingServices
    }
    
    func notifyMissingServices() {
        
        yLog(.Debug, category: .Service, message: "Notifying of missing services..")
        notifyObservers(ObserverNotification(
            observableEvent: ObservableEvent.MissingServicesDidChange,
            data: missingServices))
    }
    
    func isReachable() -> Bool {
        return reachability.isReachable ?? false
    }
    
    func currentReachabilityString() -> String {
        
        switch reachability.networkReachabilityStatus {
        case .Reachable(let connectionType):
            if connectionType == NetworkReachabilityManager.ConnectionType.EthernetOrWiFi {
                return "WiFi"
            } else {
                return "Cellular"
            }
            
        case .NotReachable:
            return "No Connection"
            
        case .Unknown:
            return "Unknown"
        }
    }
    
    func areLocationServicesEnabled() -> Bool {
        
        return CLLocationManager.locationServicesEnabled() &&
            (CLLocationManager.authorizationStatus() != .Denied &&
                CLLocationManager.authorizationStatus() != .NotDetermined)
    }
    
    func arePushNotificationsEnabled() -> Bool {
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        return (settings?.types.contains(.Alert) == true)
    }
    
    func isBackgroundRefreshEnabled() -> Bool {
        
        if (UIApplication.sharedApplication().backgroundRefreshStatus == .Available) {
            return true;
        }
        return false;
    }
    
    func isBluetoothEnabled() -> Bool {
        
        return YikesStaffEngine.sharedEngine.yLinkReporter?.centralManager.state == .PoweredOn ||
            YikesStaffEngine.sharedEngine.yLinkReporter?.centralManager.state == .Resetting
    }
    
    func startReachabilityNotifier() {
        
        reachability = NetworkReachabilityManager(host: "www.apple.com")
        
        reachability.listener = { status in
            
            switch status {
            case .Reachable(let connectionType):
                
                if connectionType == NetworkReachabilityManager.ConnectionType.EthernetOrWiFi {
                    yLog(LoggerLevel.Debug, category: LoggerCategory.Service, message: "Internet connection became REACHABLE via WiFi.")
                } else {
                    yLog(LoggerLevel.Debug, category: LoggerCategory.Service, message: "Internet connection became REACHABLE via Cellular.")
                }
                
                self.notifyMissingServices()
                
            case .NotReachable:
                
                yLog(LoggerLevel.Debug, category: LoggerCategory.Service, message: "Internet connection became UNREACHABLE.")
                self.notifyMissingServices()
                
            case .Unknown:
                break
            }
            
            print("Network Status Changed: \(status)")
        }
        
        reachability.startListening()
    }
    
    func stopReachabilityNotifier() {
        reachability.stopListening()
        reachability = nil
    }
    
    func backgroundRefreshStatusDidChange(notification: NSNotification) {
        self.notifyMissingServices()
    }
    
}

extension ServicesManager: Observable {
    
    func addObserver(observer: Observer) {
        let index = observers.indexOf { $0 === observer }
        if index == nil {
            observers.append(observer)
        }
    }
    
    func removeObserver(observer: Observer) {
        let index = observers.indexOf { $0 === observer }
        if index != nil {
            observers.removeAtIndex(index!)
        }
    }
    
    func removeAllObservers() {
        observers = []
    }
    
    func notifyObservers(notification: ObserverNotification) {
        for observer in observers {
            observer.notify(notification)
        }
    }
}
