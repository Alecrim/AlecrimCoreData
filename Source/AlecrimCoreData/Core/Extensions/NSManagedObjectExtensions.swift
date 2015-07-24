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

    public func inDataContext(dataContext otherDataContext: DataContext) throws -> Self? {
        return try self.inManagedObjectContext(managedObjectContext: otherDataContext)
    }
    
    public func inManagedObjectContext(managedObjectContext otherManagedObjectContext: NSManagedObjectContext) throws -> Self? {
        guard let managedObjectContext = self.managedObjectContext else { return nil }
        
        if managedObjectContext == otherManagedObjectContext {
            return self
        }
        
        if self.objectID.temporaryID {
            try managedObjectContext.obtainPermanentIDsForObjects([self])
        }
        
        //let otherManagedObject = try otherManagedObjectContext.existingObjectWithID(self.objectID)
        
        //return unsafeBitCast(otherManagedObject, self.dynamicType)
        
        // TODO: compiler and environment crashes if the above lines are not commented
        return nil
    }
    
}

