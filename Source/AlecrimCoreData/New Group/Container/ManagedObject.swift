//
//  ManagedObject.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 11/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// MARK: -

public typealias ManagedObject = NSManagedObject

// MARK:-

extension ManagedObject {
    
    public final func inContext(_ otherContext: ManagedObjectContext) throws -> Self {
        if self.managedObjectContext === otherContext {
            return self
        }
        
        if self.objectID.isTemporaryID {
            try otherContext.obtainPermanentIDs(for: [self])
        }
        
        let otherManagedObject = try otherContext.existingObject(with: self.objectID)
        
        return unsafeDowncast(otherManagedObject, to: type(of: self))
    }
    
}

// MARK:-

extension ManagedObject {
    
    public final func delete() {
        precondition(self.managedObjectContext != nil)
        self.managedObjectContext!.delete(self)
    }
    
    public final func refresh(mergeChanges: Bool = true) {
        precondition(self.managedObjectContext != nil)
        self.managedObjectContext!.refresh(self, mergeChanges: mergeChanges)
    }
    
}
