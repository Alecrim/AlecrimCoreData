//
//  NSFetchedResultsControllerExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

extension CoreDataQueryable {
    
    public func toFetchedResultsController(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> NSFetchedResultsController<Self.Element> {
        return NSFetchedResultsController(fetchRequest: self.toFetchRequest() as NSFetchRequest<Self.Element>, managedObjectContext: self.context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }
    
}
