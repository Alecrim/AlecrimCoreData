//
//  CoreDataTable+OSX.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-27.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

#if os(OSX)

import Foundation
    
extension CoreDataTable {

    func toArrayController() -> NSArrayController {
        
        let arrayController = NSArrayController()
        arrayController.managedObjectContext = self.dataModel.context
        arrayController.entityName = self._underlyingFetchRequest.entityName
        
        if let sortDescriptors = self._underlyingFetchRequest.sortDescriptors {
            arrayController.sortDescriptors = sortDescriptors.copy()
        }
        
        if let predicate = self._underlyingFetchRequest.predicate {
            arrayController.fetchPredicate = predicate.copy() as NSPredicate
        }
        
        arrayController.automaticallyPreparesContent = true
        arrayController.automaticallyRearrangesObjects = true
        
        let defaultFetchRequest = arrayController.defaultFetchRequest()
        defaultFetchRequest.fetchOffset = self._underlyingFetchRequest.fetchOffset
        defaultFetchRequest.fetchLimit = self._underlyingFetchRequest.fetchLimit
        defaultFetchRequest.fetchBatchSize = self._defaultFetchBatchSize

        var error: NSError? = nil
        arrayController.fetchWithRequest(nil, merge: true, error: &error)
        
        return arrayController
    }
    
}

#endif
