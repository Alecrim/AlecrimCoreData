//
//  CoreDataTable.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

class CoreDataTable<T: NSManagedObject> {
    
    // #pragma mark - public
    
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    deinit {
        println("deinit")
    }
    
    // #pragma mark - private
    
    @lazy var _defaultFetchBatchSize = 20
    @lazy var _fetchRequest = NSFetchRequest(entityName: T.getEntityName())
    
    func _sortDescriptorsFromString(string: String, defaultAscendingValue: Bool) -> NSSortDescriptor[] {
        var sortDescriptors = NSSortDescriptor[]()
        
        let sortKeys = string.componentsSeparatedByString(",") as String[]
        for sortKey in sortKeys {
            var effectiveSortKey = sortKey
            var effectiveAscending = defaultAscendingValue
            
            let sortComponents = sortKey.componentsSeparatedByString(":") as String[]
            if sortComponents.count > 1 {
                effectiveSortKey = sortComponents[0]
                effectiveAscending = Bool(sortComponents[1].toInt())
            }
            
            sortDescriptors += NSSortDescriptor(key: effectiveSortKey, ascending: effectiveAscending)
        }
        
        return sortDescriptors
    }
}

extension CoreDataTable {

    func skip(count: Int) -> Self {
        self._fetchRequest.fetchOffset = count
        return self
    }
    
    func take(count: Int) -> Self {
        self._fetchRequest.fetchLimit = count
        return self
    }

    func sortedBy(sortTerm: String, ascending: Bool = true) -> Self {
        if self._fetchRequest.sortDescriptors == nil {
            self._fetchRequest.sortDescriptors = self._sortDescriptorsFromString(sortTerm, defaultAscendingValue: ascending)
        }
        else {
            var sortDescriptors = self._fetchRequest.sortDescriptors.copy()
            sortDescriptors += self._sortDescriptorsFromString(sortTerm, defaultAscendingValue: ascending)
            self._fetchRequest.sortDescriptors = sortDescriptors
        }
        
        return self
    }
    
    func orderBy(attributeName: String) -> Self {
        return self.orderByAscending(attributeName)
    }

    func orderByAscending(attributeName: String) -> Self {
        return self.sortedBy(attributeName, ascending: true)
    }

    func orderByDescending(attributeName: String) -> Self {
        return self.sortedBy(attributeName, ascending: false)
    }

    func filteredBy(#predicate: NSPredicate) -> Self {
        if self._fetchRequest.predicate == nil {
            self._fetchRequest.predicate = predicate
        }
        else if let compoundPredicate = self._fetchRequest.predicate as? NSCompoundPredicate {
            var subpredicates = compoundPredicate.subpredicates.copy()
            subpredicates += predicate
            self._fetchRequest.predicate = NSCompoundPredicate.andPredicateWithSubpredicates(subpredicates)
        }
        else {
            let subpredicates = [ self._fetchRequest.predicate!, predicate ]
            self._fetchRequest.predicate = NSCompoundPredicate.andPredicateWithSubpredicates(subpredicates)
        }
    
        return self
    }
    
    func filteredBy<V: AnyObject>(attribute attributeName: String, value: V?) -> Self {
        var predicate: NSPredicate
        if let v = value {
            predicate = NSPredicate(format: "%K == %@", argumentArray: [ attributeName, v ])
        }
        else {
            predicate = NSPredicate(format: "%K == nil")
        }
        
        return self.filteredBy(predicate: predicate)
    }
    
    func filteredBy(#predicateFormat: String, argumentArray arguments: AnyObject[]!) -> Self {
        let predicate = NSPredicate(format: predicateFormat, argumentArray: arguments);
        return self.filteredBy(predicate: predicate)
    }
    
    func filteredBy(#predicateFormat: String, arguments argList: CVaListPointer) -> Self {
        let predicate = NSPredicate(format: predicateFormat, arguments: argList)
        return self.filteredBy(predicate: predicate)
    }
    
    func toArray() -> T[] {
        self._fetchRequest.fetchBatchSize = self._defaultFetchBatchSize
        
        var results = T[]()
        
        self.context.performBlockAndWait { [unowned self] in
            var error: NSError? = nil
            if let objects = self.context.executeFetchRequest(self._fetchRequest, error: &error) as? T[] {
                results += objects
            }
        }
        
        return results
    }
    
    // TODO: this is not working
    func toArray(completion: (T[]) -> Void) {
        self._fetchRequest.fetchBatchSize = self._defaultFetchBatchSize
        
        let asyncFetchRequest = NSAsynchronousFetchRequest(fetchRequest: self._fetchRequest) { result in
            var results = T[]()
            
            if let objects = result.finalResult as? T[] {
                results += objects
            }
            
            completion(results)
        }
        
        // TODO: verify if this is supposed to work
        /*
        context.performBlock {
        var error: NSError?  = nil
        context.executeFetchRequest(asyncRequest, error: &error)
        }
        */
        
        var error: NSError?  = nil
        self.context.persistentStoreCoordinator.executeRequest(asyncFetchRequest, withContext: self.context, error: &error)
    }
    
    func count() -> Int {
        var c = 0
        
        self.context.performBlockAndWait { [unowned self] in
            var error: NSError? = nil
            c += self.context.countForFetchRequest(self._fetchRequest, error: &error)
        }
        
        return c
    }
    
    func count(completion: (Int) -> Void) {
        self._fetchRequest.resultType = .CountResultType
        
        let asyncFetchRequest = NSAsynchronousFetchRequest(fetchRequest: self._fetchRequest) { result in
            var c = 0
            
            if let finalResult = result.finalResult as? Array<Int> {
                if !finalResult.isEmpty {
                    c += finalResult[0]
                }
            }
            
            completion(c)
        }
        
        // TODO: verify if this is supposed to work
        /*
        context.performBlock {
        var error: NSError?  = nil
        context.executeFetchRequest(asyncRequest, error: &error)
        }
        */
        
        var error: NSError?  = nil
        self.context.persistentStoreCoordinator.executeRequest(asyncFetchRequest, withContext: self.context, error: &error)
    }
    
    func first() -> T? {
        let savedFetchLimit = self._fetchRequest.fetchLimit
        let results = self.take(1).toArray()
        self._fetchRequest.fetchLimit = savedFetchLimit
        return (results.isEmpty ? nil : results[0])
    }
    
    func first(completion: (T?) -> Void) {
        // TODO: return to saved fetch limit before block completes?
        let savedFetchLimit = self._fetchRequest.fetchLimit
        self.take(1).toArray { [unowned self] results in
            self._fetchRequest.fetchLimit = savedFetchLimit
            completion(results.isEmpty ? nil : results[0])
        }
    }
    
    /*
    func last() -> T? {
        let results = self.toArray()
        return (results.count > 0 ? results[results.count - 1] : nil)
    }
    
    func last(completion: (T?) -> Void) {
        self.toArray { results in
            completion(results.count > 0 ? results[results.count - 1] : nil)
        }
    }
    */
    
    func any() -> Bool {
        let savedFetchLimit = self._fetchRequest.fetchLimit
        let result = self.take(1).count() > 0
        self._fetchRequest.fetchLimit = savedFetchLimit
        
        return result
    }
    
    func any(completion: (Bool) -> Void) {
        // TODO: return to saved fetch limit before block completes?
        let savedFetchLimit = self._fetchRequest.fetchLimit
        return self.take(1).count { [unowned self] count in
            self._fetchRequest.fetchLimit = savedFetchLimit
            completion(count > 0)
        }
    }
}

extension CoreDataTable: Sequence {

    typealias GeneratorType = IndexingGenerator<T[]>
    
    func generate() -> GeneratorType {
        return self.toArray().generate()
    }

}

extension CoreDataTable {

    func createEntity() -> T {
        let entityDescription = NSEntityDescription.entityForName(T.getEntityName(), inManagedObjectContext: self.context)
        let managedObject = T(entity: entityDescription, insertIntoManagedObjectContext: self.context)
        
        return managedObject
    }
    
    func createOrGetFirstEntity<V: AnyObject>(whereAttribute attributeName: String, isEqualTo value: V?) -> T {
        if let entity = self.filteredBy(attribute: attributeName, value: value).first() {
            return entity
        }
        else {
            let entity = self.createEntity()
            entity.setValue(value, forKey: attributeName)
            
            return entity
        }
    }
    
    func deleteEntity(managedObject: T) -> (Bool, NSError?) {
        var retrieveExistingObjectError: NSError? = nil
        
        if let managedObjectInContext = self.context.existingObjectWithID(managedObject.objectID, error: &retrieveExistingObjectError) {
            self.context.deleteObject(managedObjectInContext)
            return (managedObject.deleted || managedObject.managedObjectContext == nil, retrieveExistingObjectError)
        }
        else {
            return (false, retrieveExistingObjectError)
        }
    }

    func refreshEntity(managedObject: T) {
        managedObject.managedObjectContext.refreshObject(managedObject, mergeChanges: true)
    }

}
