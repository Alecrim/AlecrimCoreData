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
        
        if self.objectID.temporaryID {
            if let moc = self.managedObjectContext {
                var error: NSError? = nil
                let success = moc.obtainPermanentIDsForObjects([self as NSManagedObject], error: &error)
                if !success {
                    alecrimCoreDataHandleError(error)
                    return nil
                }
            }
            else {
                return nil
            }
        }
        
        var error: NSError? = nil
        let objectInContext = otherManagedObjectContext.existingObjectWithID(self.objectID, error: &error)
        
        if error != nil {
            alecrimCoreDataHandleError(error)
        }
        
        return unsafeBitCast(objectInContext, self.dynamicType)
    }
    
}

