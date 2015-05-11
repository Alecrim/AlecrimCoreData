//
//  NSManagedObjectExtensions.swift
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
    
    public func inManagedObjectContext(otherManagedObjectContext: NSManagedObjectContext) -> Self? {
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

