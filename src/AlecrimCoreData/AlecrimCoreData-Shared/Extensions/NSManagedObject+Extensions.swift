//
//  NSManagedObject+Extensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-24.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

private var entityNames = Dictionary<String, String>()

extension NSManagedObject {
    
    public func inDataModel(dataModel: CoreDataModel) -> Self? {
        return self.inContext(dataModel.context)
    }
    
    private func inContext(otherContext: NSManagedObjectContext) -> Self? {
        if self.managedObjectContext == otherContext {
            return self
        }
        
        var error: NSError? = nil
        if self.objectID.temporaryID {
            let success = self.managedObjectContext.obtainPermanentIDsForObjects([self], error: &error)
            if !success {
                return nil
            }
        }
        
        let objectInContext = otherContext.existingObjectWithID(self.objectID, error: &error)
        
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
            
            let suffix: NSString = "Entity"
            if name != suffix && name.hasSuffix(suffix) {
                name = name.substringToIndex(name.length - suffix.length)
            }
            
            entityNames[className] = name
            
            return name
        }
    }

}

