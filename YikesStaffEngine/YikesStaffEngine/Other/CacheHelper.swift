//
//  CacheHelper.swift
//  YikesStaffEngine
//
//  Created by Manny Singh on 8/18/16.
//  Copyright © 2016 yikes. All rights reserved.
//

import Foundation
import ObjectMapper

class CacheHelper {
    
    class func engineCacheDirectoryURL() -> NSURL {
        
        let cacheDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)[0]
        let engineCacheDirectoryURL = cacheDirectoryURL.URLByAppendingPathComponent("com.yikesteam.staffapp")
        
        if !engineCacheDirectoryURL.checkResourceIsReachableAndReturnError(nil) {
            _ = try? NSFileManager.defaultManager().createDirectoryAtURL(engineCacheDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        }
        
        return engineCacheDirectoryURL
    }
    
    class func pathForRootObjectOfCacheName(cacheName: String) -> NSURL {
        return engineCacheDirectoryURL().URLByAppendingPathComponent(cacheName)
    }
    
    class func getObjectWithCacheName<T: Mappable>(cacheName: String) -> T? {
        let JSONDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(pathForRootObjectOfCacheName(cacheName).path!) as? [String : AnyObject]
        return Mapper<T>().map(JSONDictionary)
    }
    
    class func saveObjectToCache<T: Mappable>(obj: T, cacheName: String) {
        let JSONDictionary = Mapper().toJSON(obj)
        NSKeyedArchiver.archiveRootObject(JSONDictionary, toFile:pathForRootObjectOfCacheName(cacheName).path!)
    }
    
    class func removeObjectWithCacheName(cacheName: String) {
        
        let path = pathForRootObjectOfCacheName(cacheName).path!
        if (NSFileManager.defaultManager().fileExistsAtPath(path)) {
            _ = try? NSFileManager.defaultManager().removeItemAtPath(path)
        }
    }
    
}
