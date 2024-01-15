//
//  FileLoggerHelper.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

public class LogFileInfo {
    
    public var filePathURL : NSURL
    
    public var fileName : String {
        return filePathURL.lastPathComponent!
    }
    
    private var _fileAttributes : [String : AnyObject]?
    var fileAttributes : [String : AnyObject] {
        
        if (_fileAttributes == nil) {
            _fileAttributes = try? NSFileManager.defaultManager().attributesOfItemAtPath(filePathURL.path!)
        }
        
        return _fileAttributes!
    }
    
    var creationDate : NSDate {
        return fileAttributes[NSFileCreationDate] as! NSDate
    }
    
    var modificationDate : NSDate {
        return fileAttributes[NSFileModificationDate] as! NSDate
    }
    
    var fileSize : CUnsignedLongLong {
        return (fileAttributes[NSFileSize] as! NSNumber).unsignedLongLongValue
    }
    
    var age: NSTimeInterval {
        return creationDate.timeIntervalSinceNow * -1.0
    }
    
    var isArchived: Bool {
        get {
            
            let fileName = filePathURL.URLByDeletingPathExtension!.lastPathComponent!
            
            if fileName.hasSuffix(FileLoggerHelper.logFileArchivedSuffix) {
                return true
            }
            return false
            
        }
        set(value) {
            
            let ext = filePathURL.pathExtension!
            let pathWithoutExt = filePathURL.URLByDeletingPathExtension!
            var fileName = pathWithoutExt.lastPathComponent!
            
            if value {
                
                // add .archived to filename
                if !fileName.hasSuffix(FileLoggerHelper.logFileArchivedSuffix) {
                    fileName += FileLoggerHelper.logFileArchivedSuffix
                    renameFile(fileName + "." + ext)
                }
            
            } else {
                
                // remove .archived from filename
                if fileName.hasSuffix(FileLoggerHelper.logFileArchivedSuffix) {
                    let pathWithoutSuffix = pathWithoutExt.URLByDeletingPathExtension!
                    renameFile(pathWithoutSuffix.lastPathComponent! + "." + ext)
                }
            }
        }
    }
    
    init(filePathURL: NSURL) {
        
        self.filePathURL = filePathURL
    }
    
    func renameFile(newFileName: String) {
        
        if (newFileName != fileName) {
            
            if let newFilePathURL = filePathURL.URLByDeletingLastPathComponent?.URLByAppendingPathComponent(newFileName) {
                
                if newFilePathURL.checkResourceIsReachableAndReturnError(nil) {
                    _ = try? NSFileManager.defaultManager().removeItemAtURL(newFilePathURL)
                }
                
                _ = try? NSFileManager.defaultManager().moveItemAtURL(filePathURL, toURL: newFilePathURL)
                
                filePathURL = newFilePathURL
                _fileAttributes = nil
            }
        }
        
    }
    
    func reverseCompareByCreationDate(another: LogFileInfo) -> NSComparisonResult {
        
        let us = creationDate
        let them = another.creationDate
        
        let result = us.compare(them)
        
        if (result == .OrderedAscending) {
            return .OrderedDescending
        }
        
        if (result == .OrderedDescending) {
            return .OrderedAscending
        }
        
        return .OrderedSame
    }
}


class FileLoggerHelper {
    
    let directory: NSURL!
    
    var logFileNamePrefix = "yikes"
    static let logFileNameExtension = "txt"
    static let logFileArchivedSuffix = ".archived"
    
    init(logsDirectory: NSURL) {
        
        if let lastComponent = logsDirectory.lastPathComponent {
            logFileNamePrefix = logFileNamePrefix + " " + lastComponent
        }
        
        print("\nLog directory: \(logsDirectory)")
        
        self.directory = logsDirectory
    }
        
    func newLogFileName() -> String {
        
        let timestamp = DateHelper.sharedInstance.simpleDateFormatterWithTime.stringFromDate(NSDate())
        let name = "\(logFileNamePrefix) \(timestamp).\(FileLoggerHelper.logFileNameExtension)".stringByReplacingOccurrencesOfString(":", withString: "-")
        
        return name.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
    }
    
    func createNewLogFile() -> NSURL {
        
        let fileURL = NSURL(string: newLogFileName())!
        
        var attempt = 1
        
        repeat {
            
            var actualFileURL = fileURL
            
            if (attempt > 1) {
                let ext = actualFileURL.pathExtension!
                actualFileURL = actualFileURL.URLByDeletingPathExtension!
                
                let newName = "\(actualFileURL.lastPathComponent!) \(attempt)".stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
                actualFileURL = NSURL(string: newName)!
                
                if (ext.characters.count > 0) {
                    actualFileURL = actualFileURL.URLByAppendingPathExtension(ext)
                }
            }
            
            let filePathURL = directory.URLByAppendingPathComponent(actualFileURL.path!)
            
            if (!filePathURL.checkResourceIsReachableAndReturnError(nil)) {
                
                NSFileManager.defaultManager().createFileAtPath(filePathURL.path!, contents: nil, attributes: nil)
                return filePathURL
                
            } else {
                attempt += 1
            }
            
        } while (true)
    }
    
    func logFileHeaderData(fileInfo: LogFileInfo) -> String {
        
        let email = SessionManager.sharedInstance.currentUser?.email ?? "No user found"
        
        ClientInfoBuilder.sharedInstance.rebuildVersionInfo()
        let info = ClientInfoBuilder.sharedInstance.info
        
        let path            = "Full session logs path and filename: \(fileInfo.filePathURL.path!)"
        
        let model           = "Device model:    \(info["model"]!)"
        let appVersion      = "Staff app version:      v\(info["StaffAppV"]!) build \(info["StaffAppB"]!)"
        let engineVersion   = "Staff engine version:  v\(info["StaffEngineV"]!)"
        let osVersion       = "iOS version:     \(info["osV"]!)"
        let userEmail       = "User email:      \(email)"
        let apiEnv          = "API env:         \(YikesStaffEngine.sharedEngine.currentApiEnv)"
        
        let creationDate    = "Full session logs started at \(DateHelper.sharedInstance.simpleDateFormatterWithTimeZone.stringFromDate(fileInfo.creationDate))"
        
        let header = path + "\n\n" +
            model + "\n" +
            appVersion + "\n" +
            engineVersion + "\n" +
            osVersion + "\n" +
            userEmail + "\n" +
            apiEnv + "\n\n" +
            creationDate + "\n\n"
        
        return header
    }
    
    func sortedLogFileInfos() -> [LogFileInfo] {
        
        guard let fileURLs = try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(directory, includingPropertiesForKeys: [], options: [.SkipsHiddenFiles])
            else { return [] }
        
        var unsortedListOfFileInfos : [LogFileInfo] = []
        
        for fileURL in fileURLs {
            
            if (fileURL.lastPathComponent!.hasPrefix(logFileNamePrefix)) {
                unsortedListOfFileInfos.append(LogFileInfo(filePathURL: fileURL))
            }
        }
        
        let sortedListOfFileInfos : [LogFileInfo] = unsortedListOfFileInfos.sort {
            return $0.reverseCompareByCreationDate($1) == .OrderedAscending
        }
        
        return sortedListOfFileInfos
    }
    
}
