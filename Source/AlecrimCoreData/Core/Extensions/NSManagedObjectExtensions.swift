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

    public func inContext(otherContext: NSManagedObjectContext) throws -> Self? {
        guard let context = self.managedObjectContext else { return nil }
        
        if context == otherContext {
            return self
        }
        
        if self.objectID.temporaryID {
            try otherContext.obtainPermanentIDsForObjects([self])
        }
        
        //let otherManagedObject = try otherContext.existingObjectWithID(self.objectID)
        
        //return unsafeBitCast(otherManagedObject, self.dynamicType)
        
        // TODO: compiler and environment crashes if the above lines are not commented
        return nil
    }
    
}

