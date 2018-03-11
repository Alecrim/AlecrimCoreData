//
//  FetchRequestController.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 11/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public final class FetchRequestController<Entity: ManagedObject> {
    
    public let rawValue: NSFetchedResultsController<Entity>
    
    public init(fetchRequest: FetchRequest<Entity>, context: ManagedObjectContext, sectionNameKeyPath: String? = nil, cacheName: String? = nil) {
        self.rawValue = NSFetchedResultsController(fetchRequest: fetchRequest.rawValue, managedObjectContext: context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
        
        try! self.rawValue.performFetch()
    }
    
}
