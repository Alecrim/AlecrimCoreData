//
//  NSManagedObjectExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-24.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// can be changed to nil or other suffix
public var entityNameSuffix: NSString? = "Entity"

// entity names cache
private var entityNames = Dictionary<String, String>()

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
        
        if let name = entityNames[className] {
            return name
        }
        else {
            var name: NSString = className
            let range = name.rangeOfString(".")
            if range.location != NSNotFound {
                name = name.substringFromIndex(range.location + 1)
            }
            
            if let suffix = entityNameSuffix {
                if !name.isEqualToString(suffix) && name.hasSuffix(suffix) {
                    name = name.substringToIndex(name.length - suffix.length)
                }
            }
            
            entityNames[className] = name
            
            return name
        }
    }
    
}

