//
//  FileLogger.swift
//  YikesEngine
//
//  Created by Manny Singh on 1/5/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

class FileLogger {
    
    let loggerQueue = dispatch_queue_create("com.yikesteam.filelogger", DISPATCH_QUEUE_SERIAL)
    
    var yLogger: YLogger?
    let logsDirectory: NSURL!
    
    var _currentLogFileHandle : NSFileHandle?
    var _currentLogFileInfo : LogFileInfo?
    
    var fileLoggerHelper : FileLoggerHelper!
    
    init(logsDirectory: NSURL) {
        
        self.logsDirectory = logsDirectory
        self.fileLoggerHelper = FileLoggerHelper(logsDirectory: logsDirectory)
    }
    
    func logMessage(logMessage: LogMessage) {
        
        dispatch_async(loggerQueue) {
            
            if let logData = self.formattedLogMessage(logMessage).dataUsingEncoding(NSUTF8StringEncoding) {
                self.currentLogFileHandle().writeData(logData)
            }
        }
    }
    
    func formattedLogMessage(logMessage: LogMessage) -> String {
        
        var message = String(logMessage.message)
        if !message.hasSuffix("\n") {
            message += "\n"
        }
        
        let timeStampString = DateHelper.sharedInstance.dateFormatterWithMilliSec.stringFromDate(logMessage.timestamp)
        let levelString = logMessage.level.description
        let categoryString = logMessage.category.rawValue
        
        return timeStampString + "  " + "[\(levelString) - \(categoryString)]" + "  " + message
    }
    
    func addHeaderDataToCurrentLogFileIfNeeded() {
        
        // check if pointer is at position 0 (assume file is blank)
        if (currentLogFileHandle().offsetInFile == 0) {
            
            let headerString = fileLoggerHelper.logFileHeaderData(currentLogFileInfo())
            if let headerData = headerString.dataUsingEncoding(NSUTF8StringEncoding) {
                currentLogFileHandle().writeData(headerData)
            }
        }
    }
    
    func currentLogFileInfo() -> LogFileInfo {
        
        if (_currentLogFileInfo == nil) {
            
            // get a list of logs files already on file
            let logFileInfos = fileLoggerHelper.sortedLogFileInfos()
            
            if (logFileInfos.count > 0) {
                
                // select the most recent file (only if it's not archived)
                
                let mostRecentFileInfo = logFileInfos[0]
                
                if (!mostRecentFileInfo.isArchived) {
                    _currentLogFileInfo = mostRecentFileInfo
                }
            }
            
            if (_currentLogFileInfo == nil) {
                
                let newLogFileURL = fileLoggerHelper.createNewLogFile()
                _currentLogFileInfo = LogFileInfo(filePathURL: newLogFileURL)
                
                // a new log file was created, see if we can remove old ones
                deleteOldLogFiles()
            }
        }
        
        return _currentLogFileInfo!
    }
    
    func currentLogFileHandle() -> NSFileHandle {
        
        if (_currentLogFileHandle == nil) {
            
            let logFilePathURL = currentLogFileInfo().filePathURL
                
            _currentLogFileHandle = try? NSFileHandle(forWritingToURL: logFilePathURL)
            _currentLogFileHandle?.seekToEndOfFile()
            
            addHeaderDataToCurrentLogFileIfNeeded()
        }
        
        return _currentLogFileHandle!
    }
    
    func rollLogFileNow() {
        
        dispatch_async(loggerQueue) {
            
            if (self._currentLogFileHandle == nil) {
                return
            }
            
            self.yLogger?.log(LoggerLevel.Debug, category: LoggerCategory.Service, message: "Rolling log file now...")
            
            self._currentLogFileHandle?.synchronizeFile()
            self._currentLogFileHandle?.closeFile()
            self._currentLogFileHandle = nil
            
            self._currentLogFileInfo?.isArchived = true
            
            self._currentLogFileInfo = nil
            
        }
    }
    
    func deleteOldLogFiles() {
        
    }
    
}
