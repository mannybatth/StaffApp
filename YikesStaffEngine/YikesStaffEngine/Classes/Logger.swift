//
//  Logger.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import Alamofire

public enum LoggerLevel : Int {
    
    
    case External = -1
    case Critical = 1
    case Error
    case Warning
    case Info
    case Debug
    
    var description : String {
        get {
            switch (self) {
            case .Critical:
                return "CRITI"
            case .Error:
                return "ERROR"
            case .Warning:
                return "WARN "
            case .Info:
                return "INFO "
            case .Debug:
                return "DEBUG"
            case .External:
                return "EXTRN"
            }
        }
    }
}

public enum LoggerCategory : String {
    
    case System     = "SYS"
    case BLE        = "BLE"
    case API        = "API"
    case Device     = "DVC"
    case Service    = "SVC"
    case YLink      = "YLK"
    case Engine     = "ENG"
}

public class LogMessage {
    
    public var level : LoggerLevel
    public var category : LoggerCategory
    public var timestamp : NSDate
    public var message : String
    
    public var filePath: String
    public var functionName : String
    public var lineNumber: Int
    
    public var tableViewCellHeight : CGFloat?
    
    public init(level: LoggerLevel, category: LoggerCategory, timestamp: NSDate, message: String, filePath: String, functionName: String, lineNumber: Int) {
        self.level = level
        self.category = category
        self.timestamp = timestamp
        self.message = message
        self.filePath = filePath
        self.functionName = functionName
        self.lineNumber = lineNumber
    }
    
}

public protocol YLoggerDelegate:class {
    func yLogger(logger: YLogger, didReceiveLogMessage logMessage: LogMessage)
}

public class YLogger {
    
    public weak var delegate : YLoggerDelegate?
    
    let fileLogger : FileLogger!
    
    public init(logsDirectory: NSURL) {
        
        fileLogger = FileLogger(logsDirectory: logsDirectory)
        fileLogger.yLogger = self
    }
    
    public func rollLogFileNow() {
        fileLogger.rollLogFileNow()
    }
    
    public func sortedLogFileInfos() -> [LogFileInfo] {
        return fileLogger.fileLoggerHelper.sortedLogFileInfos()
    }
    
    public func log(level: LoggerLevel = .Debug, category: LoggerCategory = .System, message: String, filePath: String = #file, functionName: String = #function, lineNumber: Int = #line) {
        
        let now = NSDate()
        let logMessage = LogMessage(level: level, category: category, timestamp: now, message: message, filePath: filePath, functionName: functionName, lineNumber: lineNumber)
        
        delegate?.yLogger(self, didReceiveLogMessage: logMessage)
        fileLogger.logMessage(logMessage)
        
    }
}

public func yPrint(message: String, timestamp: NSDate = NSDate(), filePath: String = #file, functionName: String = #function, lineNumber: Int = #line) {
    
    let dateString = DateHelper.sharedInstance.simpleDateFormatterWithMilliSec.stringFromDate(timestamp)
    if let fileName = NSURL(string: filePath)?.URLByDeletingPathExtension?.lastPathComponent {
        print("\(dateString) [\(fileName) \(functionName): \(lineNumber)] \(message)")
    } else {
        print("\(dateString) [\(functionName): \(lineNumber)] \(message)")
    }
}

public func yLog(level: LoggerLevel = .Debug, category: LoggerCategory = .System, message: String, filePath: String = #file, functionName: String = #function, lineNumber: Int = #line) {
    
    StaffAppLogger.sharedInstance.log(level, category: category, message: message, filePath: filePath, functionName: functionName, lineNumber: lineNumber)
    yPrint(message, timestamp: NSDate(), filePath: filePath, functionName: functionName, lineNumber: lineNumber)
}


class StaffAppLogger : YLogger {
    
    static let sharedInstance = StaffAppLogger()
    
    init() {
        super.init(logsDirectory: StaffAppLogger.logsDirectory())
    }
    
    class func logsDirectory() -> NSURL {
        
        let engineDirectoryURL = CacheHelper.engineCacheDirectoryURL()
        let logsDirectoryURL = engineDirectoryURL.URLByAppendingPathComponent("StaffAppLogs")
        
        if !logsDirectoryURL.checkResourceIsReachableAndReturnError(nil) {
            _ = try? NSFileManager.defaultManager().createDirectoryAtURL(logsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return logsDirectoryURL
    }
}



class NetworkLogger {
    
    class func logDivider() {
        print("---------------------")
    }
    
    class func logError(error: NSError) {
        logDivider()
        
        yLog(LoggerLevel.Debug, category: LoggerCategory.API, message: "Error: \(error.localizedDescription)")
        
        if HTTPManager.networkLogStyle == .Verbose {
            if let reason = error.localizedFailureReason {
                print("Reason: \(reason)")
            }
            
            if let suggestion = error.localizedRecoverySuggestion {
                print("Suggestion: \(suggestion)")
            }
        }
    }
    
    class func logRequest(request: Request) {
        logDivider()
        
        guard let req = request.request else {
            return
        }
        
        if let url = req.URL?.absoluteString {
            let currentReachabilityString = ServicesManager.sharedInstance.currentReachabilityString()
            yLog(LoggerLevel.Debug, category: LoggerCategory.API, message: "[\(request.task.taskIdentifier)] + \(req.HTTPMethod!) \(url) [cookie: \(SessionManager.sharedInstance.getSessionCookie()?.value ?? "nil")] [type: \(currentReachabilityString ?? "nil")]")
        }
        
        if HTTPManager.networkLogStyle == .Verbose {
            if let headers = req.allHTTPHeaderFields {
                self.logHeaders(headers)
            }
        }
    }
    
    class func logResponse(response: NSURLResponse, dataTask: NSURLSessionTask, data: NSData? = nil) {
        logDivider()
        
        if let url = response.URL?.absoluteString,
            let httpResponse = response as? NSHTTPURLResponse {
            let currentReachabilityString = ServicesManager.sharedInstance.currentReachabilityString()
            yLog(LoggerLevel.Debug, category: LoggerCategory.API, message: "[\(dataTask.taskIdentifier)] - \(httpResponse.statusCode) \(url) [cookie: \(SessionManager.sharedInstance.getSessionCookie()?.value ?? "nil")] [type: \(currentReachabilityString ?? "nil")]")
        }
        
        if HTTPManager.networkLogStyle == .Verbose {
            if let headers = (response as? NSHTTPURLResponse)?.allHeaderFields as? [String: AnyObject] {
                self.logHeaders(headers)
            }
            
            guard let data = data else { return }
            
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
                let pretty = try NSJSONSerialization.dataWithJSONObject(json, options: .PrettyPrinted)
                
                if let string = NSString(data: pretty, encoding: NSUTF8StringEncoding) {
                    print("JSON: \(string)")
                }
            }
                
            catch {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    print("Data: \(string)")
                }
            }
        }
    }
    
    class func logHeaders(headers: [String: AnyObject]) {
        print("Headers: [")
        for (key, value) in headers {
            print("  \(key) : \(value)")
        }
        print("]")
    }
}
