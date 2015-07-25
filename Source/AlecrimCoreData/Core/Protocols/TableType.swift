//
//  TableType.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-06-17.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public protocol TableType: GenericQueryable {
    
    typealias Entity: NSManagedObject

    var dataContext: NSManagedObjectContext { get }
    var entityDescription: NSEntityDescription { get }

}

// MARK: - create, delete and refresh entities

extension TableType {
    
    public func createEntity() -> Entity {
        let entity = Entity(entity: self.entityDescription, insertIntoManagedObjectContext: self.dataContext)

        return entity
    }

    public func deleteEntity(entity: Entity) {
        self.dataContext.deleteObject(entity)
    }
    
    public func refreshEntity(entity: Entity, mergeChanges: Bool = true) {
        self.dataContext.refreshObject(entity, mergeChanges: mergeChanges)
    }

}

extension TableType {
    
    public func delete() throws {
        let fetchRequest = self.toFetchRequest()
        fetchRequest.resultType = .ManagedObjectIDResultType
        
        let result = try self.dataContext.executeFetchRequest(fetchRequest)
        if let objectIDs = result as? [NSManagedObjectID] {
            for objectID in objectIDs {
                let object = try self.dataContext.existingObjectWithID(objectID)
                self.dataContext.deleteObject(object)
            }
        }
        else {
            throw AlecrimCoreDataError.UnexpectedValue(value: result)
        }
    }

}

extension TableType {
    
    public func firstOrCreated(@noescape predicateClosure: (Entity.Type) -> NSComparisonPredicate) -> Entity {
        let predicate = predicateClosure(Entity.self)
        
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

// MARK: - Enumerable

extension TableType {
    
    public func count() -> Int {
        var error: NSError? = nil
        let c = self.dataContext.countForFetchRequest(self.toFetchRequest(), error: &error)
        
        if error == nil && c != NSNotFound {
            return c
        }
        else {
            return 0
        }
    }
    
}


// MARK: - GenericQueryable

extension TableType {
    
    public func toArray() -> [Entity] {
        var results: [Entity] = []

        let objects = try! self.dataContext.executeFetchRequest(self.toFetchRequest())

        if let entities = objects as? [Entity] {
            results += entities
        }
        else {
            // HAX: `self.dataContext.executeFetchRequest(self.toFetchRequest()) as? [T]` may not work in certain circumstances
            results += objects.map { $0 as! Entity }
        }
        
        return results
    }
    
}

// MARK: - conversion

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

