//
//  NSManagedObject+Extensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-24.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {
    
    public func inContext(context: Context) -> Self? {
        return self.inManagedObjectContext(context.managedObjectContext)
    }
    
}

extension NSManagedObject {
    
    private func inManagedObjectContext(otherManagedObjectContext: NSManagedObjectContext) -> Self? {
        if self.managedObjectContext == otherManagedObjectContext {
            return self
        }
        
        var error: NSError? = nil
        if self.objectID.temporaryID {
            if let moc = self.managedObjectContext {
                let success = moc.obtainPermanentIDsForObjects([self as NSManagedObject], error: &error)
                if !success {
                    return nil
                }
            }
            else {
                return nil
            }
        }
        
        let objectInContext = otherManagedObjectContext.existingObjectWithID(self.objectID, error: &error)
        
        return unsafeBitCast(objectInContext, self.dynamicType)
    }
    
}

extension NSManagedObject {
    
    internal class var entityName: String {
        let className = NSStringFromClass(self)
        
        if let name = Config.cachedEntityNames[className] {
            return name
        }
        else {
            var name: NSString = className
            let range = name.rangeOfString(".")
            if range.location != NSNotFound {
                name = name.substringFromIndex(range.location + 1)
            }
            
            if let prefix = Config.entityClassNamePrefix {
                if !name.isEqualToString(prefix) && name.hasPrefix(prefix) {
                    name = name.substringFromIndex((prefix as NSString).length)
                }
            }
            
            if let suffix = Config.entityClassNameSuffix {
                if !name.isEqualToString(suffix) && name.hasSuffix(suffix) {
                    name = name.substringToIndex(name.length - (suffix as NSString).length)
                }
            }
            
            let nameAsString = name as! String
            Config.cachedEntityNames[className] = nameAsString
            
            return nameAsString
        }
    }
    
}

