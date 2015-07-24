//
//  TableType.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-06-17.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public protocol TableType: Queryable {
    
    typealias Entity: NSManagedObject

    var dataContext: NSManagedObjectContext { get }
    var entityDescription: NSEntityDescription { get }

}

// MARK: - ordering

extension TableType {
    
    public func orderByAscending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Entity.Type) -> A) -> Self {
        return self.sortByAttribute(orderingClosure(Entity.self), ascending: true)
    }

    public func orderByDescending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Entity.Type) -> A) -> Self {
        return self.sortByAttribute(orderingClosure(Entity.self), ascending: false)
    }

}

extension TableType {

    public func orderBy<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Entity.Type) -> A) -> Self {
        return self.orderByAscending(orderingClosure)
    }

    public func thenBy<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Entity.Type) -> A) -> Self {
        return self.orderByAscending(orderingClosure)
    }
    
    public func thenByAscending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Entity.Type) -> A) -> Self {
        return self.orderByAscending(orderingClosure)
    }
    
    public func thenByDescending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Entity.Type) -> A) -> Self {
        return self.orderByDescending(orderingClosure)
    }
    
}

// MARK: - filtering

extension TableType {

    public func filter(@noescape predicateClosure: (Entity.Type) -> NSPredicate) -> Self {
        return self.filterUsingPredicate(predicateClosure(Entity.self))
    }
    
}

// MARK: -

extension TableType {

    public func count(@noescape predicateClosure: (Entity.Type) -> NSPredicate) -> Int {
        return self.filterUsingPredicate(predicateClosure(Entity.self)).count()
    }

}

extension TableType {
    
    public func any(@noescape predicateClosure: (Entity.Type) -> NSPredicate) -> Bool {
        return self.filterUsingPredicate(predicateClosure(Entity.self)).any()
    }

    public func none(@noescape predicateClosure: (Entity.Type) -> NSPredicate) -> Bool {
        return self.filterUsingPredicate(predicateClosure(Entity.self)).none()
    }

}

extension TableType {

    public func first(@noescape predicateClosure: (Entity.Type) -> NSPredicate) -> Entity? {
        return self.filterUsingPredicate(predicateClosure(Entity.self)).first()
    }
    
}

// MARK: - entity

extension TableType {
    
    public func first() -> Entity? {
        return self.take(1).toArray().first
    }
    
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


// MARK: - conversion

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


