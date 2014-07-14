//
//  CoreDataTable+OSX.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-27.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

#if os(OSX)

import Foundation
import AppKit
    
extension CoreDataTable {

    func toArrayController() -> NSArrayController {
        let arrayController = NSArrayController()
        arrayController.managedObjectContext = self.dataModel.context
        arrayController.entityName = self.underlyingFetchRequest.entityName
        
        if let sortDescriptors = self.underlyingFetchRequest.sortDescriptors {
            arrayController.sortDescriptors = sortDescriptors // TODO: copy?
        }
        
        if let predicate = self.underlyingFetchRequest.predicate {
            arrayController.fetchPredicate = predicate.copy() as NSPredicate
        }
        
        arrayController.automaticallyPreparesContent = true
        arrayController.automaticallyRearrangesObjects = true
        
        let defaultFetchRequest = arrayController.defaultFetchRequest()
        defaultFetchRequest.fetchOffset = self.underlyingFetchRequest.fetchOffset
        defaultFetchRequest.fetchLimit = self.underlyingFetchRequest.fetchLimit
        defaultFetchRequest.fetchBatchSize = self.defaultFetchBatchSize

        var error: NSError? = nil
        arrayController.fetchWithRequest(nil, merge: true, error: &error)
        
        return arrayController
    }
    
}

//extension CoreDataTable {
//
//    func toFetchedResultsController() -> BBFetchedResultsController {
//        let fetchedResultsController = BBFetchedResultsController(fetchRequest: self.underlyingFetchRequest.copy() as NSFetchRequest, managedObjectContext: self.dataModel.context, sectionNameKeyPath: nil)
//        return fetchedResultsController
//    }
//    
//}
    
#endif
