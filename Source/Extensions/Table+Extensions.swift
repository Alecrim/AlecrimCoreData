//
//  Table+Extensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-07-18.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation

extension Table {
    
    public func toArrayController() -> NSArrayController {
        let arrayController = NSArrayController()
        
        arrayController.managedObjectContext = self.context.managedObjectContext
        arrayController.entityName = self.entityName
        
        arrayController.fetchPredicate = self.predicate?.copy() as? NSPredicate
        arrayController.sortDescriptors = sortDescriptors
        
        arrayController.automaticallyPreparesContent = true
        arrayController.automaticallyRearrangesObjects = true
        
        let defaultFetchRequest = arrayController.defaultFetchRequest()
        defaultFetchRequest.fetchBatchSize = self.batchSize
        defaultFetchRequest.fetchOffset = self.offset
        defaultFetchRequest.fetchLimit = self.limit
        
        var error: NSError? = nil
        let success = arrayController.fetchWithRequest(nil, merge: false, error: &error)
        
        if !success {
            println(error)
        }
        
        return arrayController
    }
    
}
