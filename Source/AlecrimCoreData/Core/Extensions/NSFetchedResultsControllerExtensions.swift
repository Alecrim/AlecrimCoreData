//
//  NSFetchedResultsControllerExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

#if os(iOS)
    
import Foundation
import CoreData

extension CoreDataQueryable {
    
    public func toFetchedResultsController(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> NSFetchedResultsController {
        return NSFetchedResultsController(fetchRequest: self.toFetchRequest(), managedObjectContext: self.dataContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }
    
}

#endif
