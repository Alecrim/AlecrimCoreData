//
//  CoreDataTable+iOS.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-07-18.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

#if os(iOS)

public extension CoreDataTable {

    func toFetchedResultsController() -> NSFetchedResultsController {
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: self.underlyingFetchRequest.copy() as NSFetchRequest, managedObjectContext: self.dataModel.context, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }

}

#endif
