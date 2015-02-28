//
//  Table.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public final class Table<T: NSManagedObject>: Query {
    
    public convenience init(context: Context) {
        self.init(context: context, entityName: T.entityName)
    }
    
    public required init(context: Context, entityName: String) {
        super.init(context: context, entityName: entityName)
    }
    
}

// MARK: create, delete and refresh entities

extension Table {
    
    public func createEntity() -> T {
        let managedObject = T(entity: self.entityDescription, insertIntoManagedObjectContext: self.context.managedObjectContext)
        
        return managedObject
    }
    
    public func createOrGetFirstEntity(whereAttribute attributeName: String, isEqualTo value: AnyObject?) -> T {
        if let entity = self.filterBy(attribute: attributeName, value: value).first() {
            return entity
        }
        else {
            let entity = self.createEntity()
            entity.setValue(value, forKey: attributeName)
            
            return entity
        }
    }
    
    public func deleteEntity(managedObject: T) -> (Bool, NSError?) {
        var retrieveExistingObjectError: NSError? = nil
        
        if let managedObjectInContext = self.context.managedObjectContext.existingObjectWithID(managedObject.objectID, error: &retrieveExistingObjectError) {
            self.context.managedObjectContext.deleteObject(managedObjectInContext)
            return (managedObject.deleted || managedObject.managedObjectContext == nil, nil)
        }
        else {
            return (false, retrieveExistingObjectError)
        }
    }
    
    public func refreshEntity(managedObject: T) {
        if let moc = managedObject.managedObjectContext {
            moc.refreshObject(managedObject, mergeChanges: true)
        }
    }
    
}

extension Table {
    
    public func delete() {
        let fetchRequest = self.toFetchRequest()
        fetchRequest.returnsObjectsAsFaults = true
        fetchRequest.includesPropertyValues = false

        var results = [T]()
        
        if let objects = self.executeFetchRequest(fetchRequest) as? [T] {
            results += objects
        }

        for entity in results {
            self.deleteEntity(entity)
        }
    }
    
}

// MARK: - sequence

extension Table: SequenceType {
    
    public typealias GeneratorType = IndexingGenerator<[T]>
    
    public func generate() -> GeneratorType {
        return self.toArray().generate()
    }
    
}


// MARK: - conversion

extension Table {
    
    public func toArray() -> [T] {
        let fetchRequest = self.toFetchRequest()
        var results = [T]()
        
        if let objects = self.executeFetchRequest(fetchRequest) as? [T] {
            results += objects
        }
        
        return results
    }
    
}

// MARK: - element

extension Table {
    
    public func first() -> T? {
        let fetchRequest = self.toFetchRequest()
        fetchRequest.fetchLimit = 1
        
        var results = [T]()
        
        if let objects = self.executeFetchRequest(fetchRequest) as? [T] {
            results += objects
        }
        
        return (results.isEmpty ? nil : results[0])
    }
    
}

// MARK: Attribute predicate support

extension Table {
    
    public func any(predicateClosure: (T.Type) -> NSPredicate) -> Bool {
        return self.filterBy(predicate: predicateClosure(T.self)).any()
    }
    
    public func count(predicateClosure: (T.Type) -> NSPredicate) -> Int {
        return self.filterBy(predicate: predicateClosure(T.self)).count()
    }
    
    public func filter(predicateClosure: (T.Type) -> NSPredicate) -> Self {
        return self.filterBy(predicate: predicateClosure(T.self))
    }
    
    public func first(predicateClosure: (T.Type) -> NSPredicate) -> T? {
        return self.filterBy(predicate: predicateClosure(T.self)).first()
    }
    
}

// MARK: Attribute ordering support

extension Table {
    
    public func orderBy<U>(orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        let attributeName = orderingClosure(T.self).name
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func orderByAscending<U>(orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        let attributeName = orderingClosure(T.self).name
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func orderByDescending<U>(orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        let attributeName = orderingClosure(T.self).name
        return self.sortBy(attributeName, ascending: false)
    }
    
    public func thenBy<U>(orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        let attributeName = orderingClosure(T.self).name
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func thenByAscending<U>(orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        let attributeName = orderingClosure(T.self).name
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func thenByDescending<U>(orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        let attributeName = orderingClosure(T.self).name
        return self.sortBy(attributeName, ascending: false)
    }
    
}

// SWIFT_BUG: Error -> Linker error if these extensions are outside this source file. Workaround -> Put the extensions here.

#if os(iOS)

extension Table {
    
    public func toFetchedResultsController(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> FetchedResultsController<T> {
        return FetchedResultsController<T>(fetchRequest: self.toFetchRequest(), managedObjectContext: self.context.managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }
    
}

#endif
