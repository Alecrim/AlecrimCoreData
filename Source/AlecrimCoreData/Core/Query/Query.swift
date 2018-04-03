//
//  Query.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 11/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// MARK: -

public struct Query<Entity: ManagedObject> {
    
    internal let context: ManagedObjectContext
    internal fileprivate(set) var fetchRequest: FetchRequest<Entity>
    
    public init(in context: ManagedObjectContext, fetchRequest: FetchRequest<Entity> = FetchRequest()) {
        self.context = context
        self.fetchRequest = fetchRequest
    }
    
}

// MARK: -

extension Query {

    //

    public func execute() -> [Entity] {
        return self.execute(fetchRequest: self.fetchRequest)
    }

    fileprivate func execute(fetchRequest: FetchRequest<Entity>) -> [Entity] {
        return try! self.context.fetch(self.fetchRequest.toRaw())
    }


    //
    
    public func count() -> Int {
        return self.count(fetchRequest: self.fetchRequest)
    }
    
    fileprivate func count(fetchRequest: FetchRequest<Entity>) -> Int {
        return try! self.context.count(for: fetchRequest.toRaw())
    }

}

// MARK: -

extension Query {
    
    public func first() -> Entity? {
        return self.execute(fetchRequest: self.fetchRequest.take(1)).first
    }
    
}

extension Query {
    
    func filtered(using predicate: Predicate<Entity>) -> Entity? {
        return self.filtered(using: predicate).first()
    }

    public func first(where rawValue: NSPredicate) -> Entity? {
        return self.filtered(using: Predicate<Entity>(rawValue: rawValue)).first()
    }
    
    public func first(where closure: () -> Predicate<Entity>) -> Entity? {
        return self.filtered(using: closure()).first()
    }
    
}

extension Query {

    public func firstOrNewEntity(where predicate: Predicate<Entity>) -> Entity {
        guard let existingEntity = self.filtered(using: predicate).first() else {
            return self.newEntity()
        }
        
        return existingEntity
    }

    public func firstOrNewEntity(where rawValue: NSPredicate) -> Entity {
        guard let existingEntity = self.filtered(using: Predicate<Entity>(rawValue: rawValue)).first() else {
            return self.newEntity()
        }
        
        return existingEntity
    }
    
    public func firstOrNewEntity(where closure: () -> Predicate<Entity>) -> Entity {
        guard let existingEntity = self.filtered(using: closure()).first() else {
            return self.newEntity()
        }
        
        return existingEntity
    }
    
}


// MARK: -

extension Query: Sequence {
    
    public func makeIterator() -> QueryIterator<Entity> {
        return QueryIterator(self.execute())
    }
    
    public struct QueryIterator<Entity>: IteratorProtocol {
        
        private let entities: [Entity]
        private var index: Int
        
        fileprivate init(_ entities: [Entity]) {
            self.entities = entities
            self.index = 0
        }
        
        public mutating func next() -> Entity? {
            guard self.index >= 0 && self.index < self.entities.count else {
                return nil
            }
            
            defer { self.index += 1 }
            
            return self.entities[index]
        }
    }
    
}

// MARK: -

extension Query {
    
    public func newEntity() -> Entity {
        return Entity(context: self.context)
    }
    
    @discardableResult
    public func insert(with entityPropertiesInitializationClosure: (Entity) -> Void) -> Entity {
        let entity = self.newEntity()
        entityPropertiesInitializationClosure(entity)
        
        return entity
    }
    
    public func delete(_ entity: Entity) {
        self.context.delete(entity)
    }
    
    public func deleteAll() throws {
        let fr = self.fetchRequest.toRaw() as NSFetchRequest<NSManagedObjectID>
        fr.resultType = .managedObjectIDResultType
        
        let objectIDs = try self.context.fetch(fr)
        
        for objectID in objectIDs {
            let object = try self.context.existingObject(with: objectID)
            self.context.delete(object)
        }
    }
    
    public func refresh(_ entity: Entity, mergeChanges: Bool = true) {
        self.context.refresh(entity, mergeChanges: mergeChanges)
    }
    
    public func refreshAll() {
        self.context.refreshAllObjects()
    }

}

// MARK: -

extension Query {

    public func toFetchRequestController<Value>(sectionName sectionNameKeyPathClosure: @autoclosure () -> KeyPath<Entity, Value>, cacheName: String? = nil) -> FetchRequestController<Entity> {
        let sectionNameKeyPath = sectionNameKeyPathClosure().pathString
        return FetchRequestController(query: self, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

    public func toFetchRequestController(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> FetchRequestController<Entity> {
        return FetchRequestController(query: self, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }
    
}

// MARK: - Queryable

extension Query: Queryable {
    
    public func skip(_ offset: Int) -> Query<Entity> {
        var clone = self
        clone.fetchRequest = clone.fetchRequest.skip(offset)
        
        return clone
    }
    
    public func take(_ limit: Int) -> Query<Entity> {
        var clone = self
        clone.fetchRequest = clone.fetchRequest.take(limit)

        return clone
    }
    
    public func setBatchSize(_ batchSize: Int) -> Query<Entity> {
        var clone = self
        clone.fetchRequest = clone.fetchRequest.setBatchSize(batchSize)
        
        return clone
    }
    
    public func filtered(using predicate: Predicate<Entity>) -> Query<Entity> {
        var clone = self
        clone.fetchRequest = clone.fetchRequest.filtered(using: predicate)
        
        return clone
    }


    public func sorted(by sortDescriptor: SortDescriptor<Entity>) -> Query<Entity> {
        var clone = self
        clone.fetchRequest = clone.fetchRequest.sorted(by: sortDescriptor)

        return clone
    }

    public func sorted(by sortDescriptors: [SortDescriptor<Entity>]) -> Query<Entity> {
        var clone = self
        clone.fetchRequest = clone.fetchRequest.sorted(by: sortDescriptors)
        
        return clone
    }

    public func sorted(by sortDescriptors: SortDescriptor<Entity>...) -> Query<Entity> {
        var clone = self
        clone.fetchRequest = clone.fetchRequest.sorted(by: sortDescriptors)
        
        return clone
    }

}
