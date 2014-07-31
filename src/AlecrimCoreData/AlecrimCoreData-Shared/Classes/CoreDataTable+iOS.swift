//
//  CoreDataTable+iOS.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-07-18.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

#if os(iOS)
    
    import Foundation
    import CoreData
    
    extension CoreDataTable {
        
        public func toFetchedResultsController() -> NSFetchedResultsController {
            let fetchedResultsController = NSFetchedResultsController(
                fetchRequest: self.toFetchRequest(),
                managedObjectContext: self.dataModel.context,
                sectionNameKeyPath: nil,
                cacheName: nil
            )
            
            return fetchedResultsController
        }
        
    }
    
#endif
