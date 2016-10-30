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
    
}

// MARK: - create, delete and refresh entities

extension TableProtocol where Self.Element: NSManagedObject {
    
    public final func create() -> Self.Element {
        return Self.Element(entity: self.entityDescription, insertInto: self.context)
    }

    public final func delete(_ entity: Self.Element) {
        self.context.delete(entity)
    }
    
    public final func refresh(_ entity: Self.Element, mergeChanges: Bool = true) {
        self.context.refresh(entity, mergeChanges: mergeChanges)
    }

}

extension TableProtocol {
    
    public final func deleteAll() {
        do {
            let fetchRequest = self.toFetchRequest() as NSFetchRequest<NSManagedObjectID>
            fetchRequest.resultType = .managedObjectIDResultType
            
            let objectIDs: [NSManagedObjectID] = try self.context.fetch(fetchRequest)
            
            for objectID in objectIDs {
                let object = try self.context.existingObject(with: objectID)
                self.context.delete(object)
            }
        }
        catch {
            AlecrimCoreDataError.handleError(error)
        }
    }

}

extension TableProtocol where Self.Element: NSManagedObject {
    
    public final func firstOrCreated(_ predicateClosure: (Self.Element.Type) -> NSComparisonPredicate) -> Self.Element {
        let predicate = predicateClosure(Self.Element.self)
        
        if let entity = self.filter(using: predicate).first() {
            return entity
        }
        else {
            let entity = self.create()
            
            let attributeName = predicate.leftExpression.keyPath
            let value: Any = predicate.rightExpression.constantValue!
            
            (entity as NSManagedObject).setValue(value, forKey: attributeName)
            
            return entity
        }
    }

}


// MARK: - GenericQueryable

extension TableProtocol {
    
    public final func execute() -> [Self.Element] {
        do {
            return try self.context.fetch(self.toFetchRequest() as NSFetchRequest<Self.Element>)
        }
        catch {
            AlecrimCoreDataError.handleError(error)
        }
    }
    
}

// MARK: - CoreDataQueryable

extension TableProtocol {
    
    public final func toFetchRequest<ResultType: NSFetchRequestResult>() -> NSFetchRequest<ResultType> {
        let fetchRequest = NSFetchRequest<ResultType>()
        
        fetchRequest.entity = self.entityDescription
        
        fetchRequest.fetchOffset = self.offset
        fetchRequest.fetchLimit = self.limit
        fetchRequest.fetchBatchSize = (self.limit > 0 && self.batchSize > self.limit ? 0 : self.batchSize)
        
        fetchRequest.predicate = self.predicate
        fetchRequest.sortDescriptors = self.sortDescriptors
        
        return fetchRequest
    }
    
}

