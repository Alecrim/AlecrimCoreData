//
//  CoreDataQueryable.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-08-08.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public protocol CoreDataQueryable: GenericQueryable {
    
    var batchSize: Int { get set }

    var dataContext: NSManagedObjectContext { get }
    var entityDescription: NSEntityDescription { get }

    func toFetchRequest() -> NSFetchRequest
    
}

// MARK: - Enumerable

extension CoreDataQueryable {
    
    public func count() -> Int {
        var error: NSError? = nil
        let c = self.dataContext.countForFetchRequest(self.toFetchRequest(), error: &error) // where is the `throws`?
        
        if let _ = error {
            // TODO: throw error?
            return 0
        }
        
        if c != NSNotFound {
            return c
        }
        else {
            return 0
        }
    }
    
}
