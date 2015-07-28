//
//  NSArrayControllerExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

#if os(OSX)
    
import Foundation
    
extension Table {

    public func toArrayController(performFetch: Bool = true) throws -> NSArrayController {
        let fetchRequest = self.toFetchRequest()
        
        let arrayController = NSArrayController(content: nil)
        
        arrayController.managedObjectContext = self.dataContext
        arrayController.entityName = fetchRequest.entityName
        
        arrayController.fetchPredicate = fetchRequest.predicate
        arrayController.sortDescriptors = fetchRequest.sortDescriptors
        
        arrayController.automaticallyPreparesContent = true
        arrayController.automaticallyRearrangesObjects = true
        arrayController.usesLazyFetching = true
        
        if performFetch {
            try arrayController.fetchWithRequest(fetchRequest, merge: false)
        }
        
        return arrayController
    }
    
}

#endif
