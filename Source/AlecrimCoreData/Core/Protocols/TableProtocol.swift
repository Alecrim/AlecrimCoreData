//
//  TableProtocol.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-06-17.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public protocol TableProtocol: CoreDataQueryable {
    
    associatedtype Item: NSManagedObject

}

// MARK: - create, delete and refresh entities

extension TableProtocol {
    
    public func createEntity() -> Self.Item {
        return Self.Item(entity: self.entityDescription, insertIntoManagedObjectContext: self.dataContext)
    }

    public func deleteEntity(entity: Self.Item) {
        self.dataContext.deleteObject(entity)
    }
    
    public func refreshEntity(entity: Self.Item, mergingChanges mergeChanges: Bool = true) {
        self.dataContext.refreshObject(entity, mergeChanges: mergeChanges)
    }

}

extension TableProtocol {
    
    public func deleteAllEntities() throws {
        let fetchRequest = self.toFetchRequest()
        fetchRequest.resultType = .ManagedObjectIDResultType
        
        let result = try self.dataContext.executeFetchRequest(fetchRequest)
        guard let objectIDs = result as? [NSManagedObjectID] else { throw AlecrimCoreDataError.unexpectedValue(result) }
        
        for objectID in objectIDs {
            let object = try self.dataContext.existingObjectWithID(objectID)
            self.dataContext.deleteObject(object)
        }
    }

}

extension TableProtocol {
    
    public func firstOrCreated(@noescape predicateClosure: (Self.Item.Type) -> NSComparisonPredicate) -> Self.Item {
        let predicate = predicateClosure(Self.Item.self)
        
        if let entity = self.filter(using: predicate).first() {
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

extension TableProtocol {
    
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
                    guard let entity = $0 as? Self.Item else { throw AlecrimCoreDataError.unexpectedValue($0) }
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

extension TableProtocol {
    
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

