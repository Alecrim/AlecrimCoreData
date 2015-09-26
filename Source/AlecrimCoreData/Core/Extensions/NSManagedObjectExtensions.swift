//
//  NSManagedObjectExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-24.
//  Copyright (c) 2014, 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {

    public func inContext(otherContext: NSManagedObjectContext) throws -> Self {
        if self.managedObjectContext === otherContext {
            return self
        }
        
        if self.objectID.temporaryID {
            try otherContext.obtainPermanentIDsForObjects([self])
        }
        
        let otherManagedObject = try otherContext.existingObjectWithID(self.objectID)
        
        return unsafeBitCast(otherManagedObject, self.dynamicType)
    }
    
}

extension NSManagedObject {
    
    public func delete() {
        self.managedObjectContext!.deleteObject(self)
    }
    
    public func refresh(mergeChanges: Bool = true) {
        self.managedObjectContext!.refreshObject(self, mergeChanges: mergeChanges)
    }

}
