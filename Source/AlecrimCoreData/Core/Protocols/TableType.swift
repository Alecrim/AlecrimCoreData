//
//  TableType.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-06-17.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public protocol TableType: CoreDataQueryable {
    
    typealias Item: NSManagedObject

}

// MARK: - create, delete and refresh entities

extension TableType {
    
    public func createEntity() -> Self.Item {
        return Self.Item(entity: self.entityDescription, insertIntoManagedObjectContext: self.dataContext)
    }

    public func deleteEntity(entity: Self.Item) {
        self.dataContext.deleteObject(entity)
    }
    
    public func refreshEntity(entity: Self.Item, mergeChanges: Bool = true) {
        self.dataContext.refreshObject(entity, mergeChanges: mergeChanges)
    }

}

extension TableType {
    
    public func delete() throws {
        let fetchRequest = self.toFetchRequest()
        fetchRequest.resultType = .ManagedObjectIDResultType
        
        let result = try self.dataContext.executeFetchRequest(fetchRequest)
        guard let objectIDs = result as? [NSManagedObjectID] else { throw AlecrimCoreDataError.UnexpectedValue(value: result) }
        
        for objectID in objectIDs {
            let object = try self.dataContext.existingObjectWithID(objectID)
            self.dataContext.deleteObject(object)
        }
    }

}

extension TableType {
    
    public func firstOrCreated(@noescape predicateClosure: (Self.Item.Type) -> NSComparisonPredicate) -> Self.Item {
        let predicate = predicateClosure(Self.Item.self)
        
        if let entity = self.filterUsingPredicate(predicate).first() {
            return entity
        }
        else {
            let entity = self.createEntity()
            
            let attributeName = predicate.leftExpression.keyPath
            let value: AnyObject = predicate.rightExpression.constantValue
            
            (entity as NSManagedObject).setValue(value, forKey: attributeName)
            
            return entity
        }
    }

}


// MARK: - GenericQueryable

extension TableType {
    
    public func toArray() -> [Self.Item] {
        do {
            var results: [Self.Item] = []
            
            let objects = try self.dataContext.executeFetchRequest(self.toFetchRequest())
            
            if let entities = objects as? [Self.Item] {
                results += entities
            }
            else {
                // HAX: the previous cast may not work in certain circumstances
                try objects.forEach {
                    guard let entity = $0 as? Self.Item else { throw AlecrimCoreDataError.UnexpectedValue(value: $0) }
                    results.append(entity)
                }
            }
            
            return results
        }
        catch let error {
            AlecrimCoreDataError.handleError(error)
        }
    }
    
}

// MARK: - CoreDataQueryable

extension TableType {
    
    public func toFetchRequest() -> NSFetchRequest {
        let fetchRequest = NSFetchRequest()
        
        fetchRequest.entity = self.entityDescription
        
        fetchRequest.fetchOffset = self.offset
        fetchRequest.fetchLimit = self.limit
        fetchRequest.fetchBatchSize = (self.limit > 0 && self.batchSize > self.limit ? 0 : self.batchSize)
        
        fetchRequest.predicate = self.predicate
        fetchRequest.sortDescriptors = self.sortDescriptors
        
        return fetchRequest
    }
    
}

