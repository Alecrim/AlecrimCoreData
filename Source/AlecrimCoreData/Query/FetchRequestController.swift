//
//  FetchRequestController.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 11/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

//
// we cannot inherit from `NSFetchedResultsController` here because the error:
// "inheritance from a generic Objective-C class 'NSFetchedResultsController' must bind type parameters of
// 'NSFetchedResultsController' to specific concrete types"
// and
// `FetchRequestController<Entity: ManagedObject>: NSFetchedResultsController<NSFetchRequestResult>` will not work for us
// (curiously the "rawValue" inside our class is accepted to be `NSFetchedResultsController<Entity>`)
//

public final class FetchRequestController<Entity: ManagedObject> {
    
    public let rawValue: NSFetchedResultsController<Entity>
    
    public init(fetchRequest: FetchRequest<Entity>, context: ManagedObjectContext, sectionNameKeyPath: String? = nil, cacheName: String? = nil) {
        self.rawValue = NSFetchedResultsController(fetchRequest: fetchRequest.rawValue, managedObjectContext: context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
        
        try! self.rawValue.performFetch()
    }
    
}
