//
//  DataMapper.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

func copyValueTo<T>(inout field: T, object: T?) {
    if let value = object {
        field = value
    }
}

func copyValueTo<T>(inout field: T?, object: T?) {
    if let value = object {
        field = value
    }
}

infix operator <- {}

func <- <T>(inout left: T, right: DataMap) {
    if right.dataMappingType == DataMappingType.FromData {
        
        // convert NSData to values here
        
        let data: NSData = right.currentDataValue!
        
        switch left {
        case is UInt8:
            
            copyValueTo(&left, object: data.convertToBytes().first! as? T)
            
        case is [UInt8]:
            
            copyValueTo(&left, object: data.convertToBytes() as? T)
            
        case is UInt16:
            
            copyValueTo(&left, object: UnsafePointer<UInt16>(data.convertToBytes()).memory as? T)
            
        case is UInt32:
            
            copyValueTo(&left, object: UnsafePointer<UInt32>(data.convertToBytes()).memory as? T)
            
        case is Int8:
            
            copyValueTo(&left, object: data.convertToSignedBytes().first! as? T)
            
        case is [Int8]:
            
            copyValueTo(&left, object: data.convertToSignedBytes() as? T)
            
        case is Int16:
            
            copyValueTo(&left, object: UnsafePointer<Int16>(data.convertToSignedBytes()).memory as? T)
            
        case is Int32:
            
            copyValueTo(&left, object: UnsafePointer<Int32>(data.convertToSignedBytes()).memory as? T)
            
        case is String:
            
            let string = String(data: data, encoding: NSUTF8StringEncoding)
            copyValueTo(&left, object: string as? T)
            
        default:
            copyValueTo(&left, object: right.currentDataValue as? T)
        }
        
    } else {
        
        // convert values to NSData here
        
        var data: NSData
        
        switch left {
        case let byte as UInt8:
            data = NSData(bytes: [byte] as [UInt8], length: 1)
            
        case let bytes as [UInt8]:
            data = NSData(bytes: bytes, length: bytes.count)
            
        case let byte as UInt16:
            data = NSData(bytes: [byte] as [UInt16], length: 2)
            
        case let byte as UInt32:
            data = NSData(bytes: [byte] as [UInt32], length: 4)
            
        case let byte as Int8:
            data = NSData(bytes: [byte] as [Int8], length: 1)
            
        case let bytes as [Int8]:
            data = NSData(bytes: bytes, length: bytes.count)
            
        case let byte as Int16:
            data = NSData(bytes: [byte] as [Int16], length: 2)
            
        case let byte as Int32:
            data = NSData(bytes: [byte] as [Int32], length: 4)
            
        case let str as String:
            data = str.dataUsingEncoding(NSUTF8StringEncoding)!
            
        default:
            data = left as! NSData
        }
        
        right.rawData?.appendData(data)
    }
}



func <- <T>(inout left: T?, right: DataMap) {
    if right.dataMappingType == DataMappingType.FromData {
        
        // convert NSData to values here
        
        let data: NSData = right.currentDataValue!
        
        switch left {
        case is UInt8?:
            
            copyValueTo(&left, object: data.convertToBytes().first! as? T)
            
        case is [UInt8]?:
            
            copyValueTo(&left, object: data.convertToBytes() as? T)
            
        case is UInt16?:
            
            copyValueTo(&left, object: UnsafePointer<UInt16>(data.convertToBytes()).memory as? T)
            
        case is UInt32?:
            
            copyValueTo(&left, object: UnsafePointer<UInt32>(data.convertToBytes()).memory as? T)
            
        case is Int8?:
            
            copyValueTo(&left, object: data.convertToSignedBytes().first! as? T)
            
        case is [Int8]?:
            
            copyValueTo(&left, object: data.convertToSignedBytes() as? T)
            
        case is Int16?:
            
            copyValueTo(&left, object: UnsafePointer<Int16>(data.convertToSignedBytes()).memory as? T)
            
        case is Int32?:
            
            copyValueTo(&left, object: UnsafePointer<Int32>(data.convertToSignedBytes()).memory as? T)
            
        case is String?:
            
            let string = String(data: data, encoding: NSUTF8StringEncoding)
            copyValueTo(&left, object: string as? T)
            
        default:
            copyValueTo(&left, object: right.currentDataValue as? T)
        }
        
    } else {
        
        // convert values to NSData here
        
        var data: NSData
        
        if (left != nil) {
            
            switch left {
            case let byte as UInt8?:
                data = NSData(bytes: [byte!] as [UInt8], length: 1)
                
            case let bytes as [UInt8]?:
                data = NSData(bytes: bytes!, length: bytes!.count)
                
            case let byte as UInt16?:
                data = NSData(bytes: [byte!] as [UInt16], length: 2)
                
            case let byte as UInt32?:
                data = NSData(bytes: [byte!] as [UInt32], length: 4)
                
            case let byte as Int8?:
                data = NSData(bytes: [byte!] as [Int8], length: 1)
                
            case let bytes as [Int8]?:
                data = NSData(bytes: bytes!, length: bytes!.count)
                
            case let byte as Int16?:
                data = NSData(bytes: [byte!] as [Int16], length: 2)
                
            case let byte as Int32?:
                data = NSData(bytes: [byte!] as [Int32], length: 4)
                
            case let str as String?:
                data = str!.dataUsingEncoding(NSUTF8StringEncoding)!
                
            default:
                data = left as! NSData
            }
            
        } else {
            
            let bytes = [UInt8](count: right.currentLength!, repeatedValue: 0)
            data = NSData(bytes: bytes, length: right.currentLength!)
            
        }
        
        right.rawData?.appendData(data)
    }
}

enum DataMappingType {
    case FromData
    case ToData
}

class DataMap {
    
    let dataMappingType: DataMappingType
    
    var rawData: NSMutableData?
    
    var currentStart: Int?
    var currentLength: Int?
    var currentDataValue: NSData?
    
    init(mappingType: DataMappingType, rawData: NSData) {
        self.dataMappingType = mappingType
        self.rawData = NSMutableData(data: rawData)
    }
    
    subscript(start start: Int, length length: Int) -> DataMap {
        currentStart = start
        currentLength = length
        if (dataMappingType == .FromData) {
            currentDataValue = rawData![start: start, length: length]
        }
        return self
    }
    
    subscript(toEndFrom start: Int) -> DataMap {
        currentStart = start
        currentLength = rawData!.length
        if (dataMappingType == .FromData) {
            currentDataValue = rawData![start: start, length: rawData!.length]
        }
        return self
    }
    
}

protocol DataMappable {
    init?(_ map: DataMap)
    mutating func mapping(map: DataMap)
}


class Message : DataMappable {
    
    class var identity : UInt8 { return 0x00 }
    class var version : UInt8 { return 0x01 }
    
    init() {}
    required init?(_ map: DataMap) {}
    func mapping(map: DataMap) {}
    
    var rawData : NSData? {
        let dataMap = DataMap(mappingType: .ToData, rawData: NSData())
        self.mapping(dataMap)
        return dataMap.rawData
    }
    
    convenience init?(rawData: NSData) {
        let dataMap = DataMap(mappingType: .FromData, rawData: rawData)
        self.init(dataMap)
        self.mapping(dataMap)
    }
    
    class func isThisMessageType(rawData: NSData) -> Bool {
        
        let messageID = rawData.convertToBytes().first!
        if messageID == self.identity {
            return true
        }
        return false
    }
    
    class func bytesToHexString(bytes: [UInt8]) -> String {
        return bytes.map{String(format: "%02X", $0)}.joinWithSeparator("")
    }
    
    class func generateRandomBytes(length: Int) -> [UInt8] {
        
        var bytes = [UInt8](count: length, repeatedValue: 0)
        _ = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
        return bytes
    }
    
}

