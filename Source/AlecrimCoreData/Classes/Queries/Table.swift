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
    
    private lazy var entityDescription: NSEntityDescription = { return NSEntityDescription.entityForName(self.entityName, inManagedObjectContext: self.context.managedObjectContext)! }()
    
    public convenience init(context: Context) {
        let entityName = context.contextOptions.entityNameFromClass(T.self)
        self.init(context: context, entityName: entityName)
    }
    
    public required init(context: Context, entityName: String) {
        super.init(context: context, entityName: entityName)
    }
    
    public override func toFetchRequest() -> NSFetchRequest {
        let fetchRequest = super.toFetchRequest()
        fetchRequest.entity = self.entityDescription
        
        return fetchRequest
    }
    
}

// MARK: create, delete and refresh entities

extension Table {
    
    public func createEntity() -> T {
        let entity = T(entity: self.entityDescription, insertIntoManagedObjectContext: self.context.managedObjectContext)
        return entity
    }

    public func firstOrCreated(whereAttribute attributeName: String, isEqualTo value: AnyObject?) -> T {
        if let entity = self.filterBy(attribute: attributeName, value: value).first() {
            return entity
        }
        else {
            let entity = self.createEntity()
            entity.setValue(value, forKey: attributeName)
            
            return entity
        }
    }

    public func deleteEntity(entity: T) -> (Bool, NSError?) {
        var retrieveExistingObjectError: NSError? = nil
        
        if let managedObjectInContext = self.context.managedObjectContext.existingObjectWithID(entity.objectID, error: &retrieveExistingObjectError) {
            self.context.managedObjectContext.deleteObject(managedObjectInContext)
            return (entity.deleted || entity.managedObjectContext == nil, nil)
        }
        else {
            return (false, retrieveExistingObjectError)
        }
    }
    
    public func refreshEntity(entity: T, mergeChanges: Bool = true) {
        if let moc = entity.managedObjectContext {
            moc.refreshObject(entity, mergeChanges: mergeChanges)
        }
    }
    
}

extension Table {
    
    public func delete() -> (Bool, [NSError]?) {
        let fetchRequest = self.toFetchRequest()
        fetchRequest.resultType = .ManagedObjectIDResultType

        var errors = [NSError]()
        
        if let objectIDs = self.executeFetchRequest(fetchRequest) as? [NSManagedObjectID] {
            for objectID in objectIDs {
                var retrieveExistingObjectError: NSError? = nil

                if let object = self.context.managedObjectContext.existingObjectWithID(objectID, error: &retrieveExistingObjectError) {
                    self.context.managedObjectContext.deleteObject(object)
                }
                
                if let retrieveExistingObjectError = retrieveExistingObjectError {
                    errors.append(retrieveExistingObjectError)
                }
            }
        }
        
        if errors.count == 0 {
            return (true, nil)
        }
        else {
            return (false, errors)
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

// MARK: - Attribure - create, delete and refresh entities

extension Table {

    /// Try to find the first entity matching the comparison. If the entity does not exist a new one will be created.
    ///
    /// :param: predicateClosure A closure with a simple equality comparison between an attribute and a value.
    ///
    /// :returns: The found entity or a new entity from the same type (with the attribute filled with the specified value).
    public func firstOrCreated(predicateClosure: (T.Type) -> NSComparisonPredicate) -> T {
        let predicate = predicateClosure(T.self)
        if let entity = self.filterBy(predicate: predicate).first() {
            return entity
        }
        else {
            let entity = self.createEntity()

            let attributeName = predicate.leftExpression.keyPath
            let value: AnyObject = predicate.rightExpression.constantValue
            
            entity.setValue(value, forKey: attributeName)
            
            return entity
        }
    }
    
}


// MARK: - Attribute - predicate support

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

// MARK: - Attribute - ordering support

extension Table {
    
    public func orderBy<U>(orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        let attributeName = orderingClosure(T.self).___name
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func orderByAscending<U>(orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        let attributeName = orderingClosure(T.self).___name
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func orderByDescending<U>(orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        let attributeName = orderingClosure(T.self).___name
        return self.sortBy(attributeName, ascending: false)
    }
    
    public func thenBy<U>(orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        let attributeName = orderingClosure(T.self).___name
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func thenByAscending<U>(orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        let attributeName = orderingClosure(T.self).___name
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func thenByDescending<U>(orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        let attributeName = orderingClosure(T.self).___name
        return self.sortBy(attributeName, ascending: false)
    }
    
}

// MARK: - Attribute - aggregate

extension Table {
    
    public func sum<U>(attributeClosure: (T.Type) -> Attribute<U>) -> U {
        return self.aggregateWithFunctionName("sum", attributeClosure: attributeClosure)
    }

    public func min<U>(attributeClosure: (T.Type) -> Attribute<U>) -> U {
        return self.aggregateWithFunctionName("min", attributeClosure: attributeClosure)
    }

    public func max<U>(attributeClosure: (T.Type) -> Attribute<U>) -> U {
        return self.aggregateWithFunctionName("max", attributeClosure: attributeClosure)
    }

    public func average<U>(attributeClosure: (T.Type) -> Attribute<U>) -> U {
        return self.aggregateWithFunctionName("average", attributeClosure: attributeClosure)
    }

    private func aggregateWithFunctionName<U>(functionName: String, attributeClosure: (T.Type) -> Attribute<U>) -> U {
        let attribute = attributeClosure(T.self)
        let attributeDescription = self.entityDescription.attributesByName[attribute.___name] as! NSAttributeDescription
        
        let keyPathExpression = NSExpression(forKeyPath: attribute.___name)
        let functionExpression = NSExpression(forFunction: "\(functionName):", arguments: [keyPathExpression])
        
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = "___\(functionName)"
        expressionDescription.expression = functionExpression
        expressionDescription.expressionResultType = attributeDescription.attributeType
        
        let fetchRequest = self.toFetchRequest()
        fetchRequest.propertiesToFetch =  [expressionDescription]
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        
        var error: NSError? = nil
        let results = self.context.executeFetchRequest(fetchRequest, error: &error)
        
        let value: AnyObject = (results!.first as! NSDictionary).valueForKey(expressionDescription.name)!
        if let safeValue = value as? U {
            return safeValue
        }
        else {
            // HAX: try brute force
            return unsafeBitCast(value, U.self)
        }
    }

}



// MARK: - asynchronous fetch

extension Table {
    
    public func fetchAsync(completionClosure: ([T]!, NSError?) -> Void) -> FetchAsyncHandler {
        return self.context.executeAsynchronousFetchRequestWithFetchRequest(self.toFetchRequest()) { objects, error in
            completionClosure(objects as? [T], error)
        }
    }

}

// MARK: - batch updates

extension Table {

    public func batchUpdate(propertiesToUpdate: [NSString : AnyObject], completionClosure: (Int, NSError?) -> Void) {
        let batchUpdatePredicate = self.predicate ?? NSPredicate(value: true)
        
        self.context.executeBatchUpdateRequestWithEntityDescription(
            self.entityDescription,
            propertiesToUpdate: propertiesToUpdate,
            predicate: batchUpdatePredicate
        ) { updatedObjectsCount, error in
            dispatch_async(dispatch_get_main_queue()) {
                completionClosure(updatedObjectsCount, error)
            }
        }
    }

    public func batchUpdate<U>(attributeToUpdateClosure: (T.Type) -> (Attribute<U>, U), completionClosure: (Int, NSError?) -> Void) {
        let attributeAndValue = attributeToUpdateClosure(T.self)
        var propertiesToUpdate = [NSString : AnyObject]()

        propertiesToUpdate[attributeAndValue.0.___name as NSString] = attributeAndValue.1 as? AnyObject
        
        self.batchUpdate(propertiesToUpdate, completionClosure: completionClosure)
    }
    
}

// MARK: - AttributeQuery support

extension Table {

    public func select(propertiesToFetch: [String]) -> AttributeQuery {
        let attributeQuery = AttributeQuery(previousQuery: self, propertiesToFetch: propertiesToFetch)
        return attributeQuery
    }

    public func select<U>(attributeToSelectClosure: (T.Type) -> Attribute<U>) -> AttributeQuery {
        return self.select([attributeToSelectClosure(T.self).___name])
    }
    
    public func select() -> AttributeQuery {
        let propertiesToFetch = (self.entityDescription.attributesByName as NSDictionary).allKeys as! [String]
        return self.select(propertiesToFetch)
    }
    
    public func distinct() -> AttributeQuery {
        return self.select().distinct()
    }

}

// MARK: - iOS and OS X helper extensions

extension Table {

    public func toFetchedResultsController(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> FetchedResultsController<T> {
        return FetchedResultsController<T>(fetchRequest: self.toFetchRequest(), managedObjectContext: self.context.managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

    public func toNativeFetchedResultsController(sectionNameKeyPath: String? = nil, cacheName: String? = nil, performFetch: Bool = true) -> NSFetchedResultsController {
        let frc = NSFetchedResultsController(fetchRequest: self.toFetchRequest(), managedObjectContext: self.context.managedObjectContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
        
        if performFetch {
            var error: NSError? = nil
            let success = frc.performFetch(&error)
        }
        
        return frc
    }

}
    
// MARK: - OS X helper extensions

#if os(OSX)
    
extension Table {
        
    public func toArrayController() -> NSArrayController {
        let fetchRequest = self.toFetchRequest()
        
        let arrayController = NSArrayController(content: nil)
        
        arrayController.managedObjectContext = self.context.managedObjectContext
        arrayController.entityName = fetchRequest.entityName
        
        arrayController.fetchPredicate = fetchRequest.predicate
        arrayController.sortDescriptors = fetchRequest.sortDescriptors
        
        arrayController.automaticallyPreparesContent = true
        arrayController.automaticallyRearrangesObjects = true
        arrayController.usesLazyFetching = true
        
        var error: NSError? = nil
        let success = arrayController.fetchWithRequest(fetchRequest, merge: false, error: &error)
        
        if !success {
            alecrimCoreDataHandleError(error)
        }
        
        return arrayController
    }
    
}
    
#endif
