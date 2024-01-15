//
//  NSData+yikes.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation

extension NSData {
    subscript(start start: Int, length length: Int) -> NSData {
        
        var len = length
        
        if start > self.length-1 {
            return NSData()
        }
        
        if start + len > self.length {
            len = self.length - start
        }
        
        return self.subdataWithRange(NSMakeRange(start, len))
    }
    
    func hexadecimalString() -> String {
        var string = ""
        var byte: UInt8 = 0
        
        for i in 0 ..< self.length {
            getBytes(&byte, range: NSMakeRange(i, 1))
            string += String(format: "%02x", byte)
        }
        
        return string
    }
    
    func convertToBytes() -> [UInt8] {
        
        let count = self.length / sizeof(UInt8)
        var bytes = [UInt8](count: count, repeatedValue: 0)
        self.getBytes(&bytes, length:count * sizeof(UInt8))
        return bytes
    }
    
    func convertToSignedBytes() -> [Int8] {
        
        let count = self.length / sizeof(Int8)
        var bytes = [Int8](count: count, repeatedValue: 0)
        self.getBytes(&bytes, length:count * sizeof(Int8))
        return bytes
    }
}
