//
//  Table.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

private var cachedEntityDescriptions = [String : NSEntityDescription]()

private func entityDescriptionFromClass(aClass: AnyClass, context: NSManagedObjectContext) -> NSEntityDescription {
    let managedObjectClassName = NSStringFromClass(aClass)
    
    //
    let ed: NSEntityDescription
    if let cachedEntityDescription = cachedEntityDescriptions[managedObjectClassName] {
        ed = cachedEntityDescription
    }
    else {
        let persistentStoreCoordinator = context.persistentStoreCoordinator!
        let managedObjectModel = persistentStoreCoordinator.managedObjectModel
        
        ed = Swift.filter(managedObjectModel.entities, { $0.managedObjectClassName == managedObjectClassName }).first! as! NSEntityDescription
        cachedEntityDescriptions[managedObjectClassName] = ed
    }
    
    return ed
}


// MARK: -

public final class Table<T: NSManagedObject>: Query {
    
    private var _entityDescription: NSEntityDescription!
    private var entityDescription: NSEntityDescription {
        if self._entityDescription == nil {
            self._entityDescription = entityDescriptionFromClass(T.self, self.context)
        }
        
        return self._entityDescription
    }
    
    public convenience init(context: Context) {
        let entityDescription = entityDescriptionFromClass(T.self, context)
        self.init(context: context, entityName: entityDescription.name!)
        self._entityDescription = entityDescription
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
        let entity = T(entity: self.entityDescription, insertIntoManagedObjectContext: self.context)
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

    public func deleteEntity(entity: T) -> (success: Bool, error: NSError?) {
        var retrieveExistingObjectError: NSError? = nil
        
        if let managedObjectInContext = self.context.existingObjectWithID(entity.objectID, error: &retrieveExistingObjectError) {
            self.context.deleteObject(managedObjectInContext)
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
    
    public func delete() -> (success: Bool, errors: [NSError]?) {
        let fetchRequest = self.toFetchRequest()
        fetchRequest.resultType = .ManagedObjectIDResultType

        var errors = [NSError]()
        
        if let objectIDs = self.executeFetchRequest(fetchRequest) as? [NSManagedObjectID] {
            for objectID in objectIDs {
                var retrieveExistingObjectError: NSError? = nil

                if let object = self.context.existingObjectWithID(objectID, error: &retrieveExistingObjectError) {
                    self.context.deleteObject(object)
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
        var results = [T]()
        
        if let objects = self.executeFetchRequest(self.toFetchRequest()) {
            if let entities = objects as? [T] {
                results += entities
            }
            else {
                // HAX: `self.executeFetchRequest(fetchRequest) as? [T]` may not work in Swift 1.x in some circumstances
                results += objects.map { $0 as! T }
            }
        }
        
        return results
    }
}

// MARK: - element

extension Table {
    
    public func first() -> T? {
        return self.take(1).toArray().first
    }
    
}

// MARK: - Attribure - create, delete and refresh entities

extension Table {

    /// Try to find the first entity matching the comparison. If the entity does not exist a new one will be created.
    ///
    /// :param: predicateClosure A closure with a simple equality comparison between an attribute and a value.
    ///
    /// :returns: The found entity or a new entity from the same type (with the attribute filled with the specified value).
    public func firstOrCreated(@noescape predicateClosure: (T.Type) -> NSComparisonPredicate) -> T {
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
    
    public func any(@noescape predicateClosure: (T.Type) -> NSPredicate) -> Bool {
        return self.filterBy(predicate: predicateClosure(T.self)).any()
    }
    
    public func count(@noescape predicateClosure: (T.Type) -> NSPredicate) -> Int {
        return self.filterBy(predicate: predicateClosure(T.self)).count()
    }
    
    public func filter(@noescape predicateClosure: (T.Type) -> NSPredicate) -> Self {
        return self.filterBy(predicate: predicateClosure(T.self))
    }
    
    public func first(@noescape predicateClosure: (T.Type) -> NSPredicate) -> T? {
        return self.filterBy(predicate: predicateClosure(T.self)).first()
    }
    
}

// MARK: - Attribute - ordering support

extension Table {
    
    public func orderBy<U>(@noescape orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        return self.sortBy(orderingClosure(T.self).___name, ascending: true)
    }
    
    public func orderByAscending<U>(@noescape orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        return self.sortBy(orderingClosure(T.self).___name, ascending: true)
    }
    
    public func orderByDescending<U>(@noescape orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        return self.sortBy(orderingClosure(T.self).___name, ascending: false)
    }
    
    public func thenBy<U>(@noescape orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        return self.sortBy(orderingClosure(T.self).___name, ascending: true)
    }
    
    public func thenByAscending<U>(@noescape orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        return self.sortBy(orderingClosure(T.self).___name, ascending: true)
    }
    
    public func thenByDescending<U>(@noescape orderingClosure: (T.Type) -> Attribute<U>) -> Self {
        return self.sortBy(orderingClosure(T.self).___name, ascending: false)
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

    private func aggregateWithFunctionName<U>(functionName: String, @noescape attributeClosure: (T.Type) -> Attribute<U>) -> U {
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
    
    public func fetchAsync(completionHandler: ([T]!, NSError?) -> Void) -> FetchAsyncHandler {
        return self.context.executeAsynchronousFetchRequestWithFetchRequest(self.toFetchRequest()) { objects, error in
            completionHandler(objects as? [T], error)
        }
    }

}

// MARK: - batch updates

extension Table {

    public func batchUpdate(propertiesToUpdate: [NSString : AnyObject], completionHandler: (Int, NSError?) -> Void) {
        let batchUpdatePredicate = self.predicate ?? NSPredicate(value: true)
        
        self.context.executeBatchUpdateRequestWithEntityDescription(
            self.entityDescription,
            propertiesToUpdate: propertiesToUpdate,
            predicate: batchUpdatePredicate
        ) { updatedObjectsCount, error in
            dispatch_async(dispatch_get_main_queue()) {
                completionHandler(updatedObjectsCount, error)
            }
        }
    }

    public func batchUpdate<U>(@noescape attributeToUpdateClosure: (T.Type) -> (Attribute<U>, U), completionHandler: (Int, NSError?) -> Void) {
        let attributeAndValue = attributeToUpdateClosure(T.self)
        var propertiesToUpdate = [NSString : AnyObject]()

        propertiesToUpdate[attributeAndValue.0.___name as NSString] = attributeAndValue.1 as? AnyObject
        
        self.batchUpdate(propertiesToUpdate, completionHandler: completionHandler)
    }
    
}

// MARK: - AttributeQuery support

extension Table {

    public func select(propertiesToFetch: [String]) -> AttributeQuery {
        let attributeQuery = AttributeQuery(previousQuery: self, propertiesToFetch: propertiesToFetch)
        return attributeQuery
    }

    public func select<U>(@noescape attributeToSelectClosure: (T.Type) -> Attribute<U>) -> AttributeQuery {
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

    public func toFetchedResultsController<U>(@noescape sectionNameKeyPathClosure: (T.Type) -> Attribute<U>) -> FetchedResultsController<T> {
        let sectionNameKeyPath = sectionNameKeyPathClosure(T.self).___name
        return self.toFetchedResultsController(sectionNameKeyPath: sectionNameKeyPath, cacheName:
            nil)
    }
    
    public func toFetchedResultsController(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> FetchedResultsController<T> {
        return FetchedResultsController<T>(fetchRequest: self.toFetchRequest(), managedObjectContext: self.context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

    public func toNativeFetchedResultsController(sectionNameKeyPath: String? = nil, cacheName: String? = nil, performFetch: Bool = true) -> NSFetchedResultsController {
        let frc = NSFetchedResultsController(fetchRequest: self.toFetchRequest(), managedObjectContext: self.context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
        
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
        
        arrayController.managedObjectContext = self.context
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
