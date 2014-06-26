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
            if sortComponents.count > 0 {
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
    
    func `where`<V: AnyObject>(attribute attributeName: String, isEqualTo value: V?) -> Self {
        var predicate: NSPredicate
        if let v = value {
            predicate = NSPredicate(format: "%K == %@", argumentArray: [ attributeName, v ])
        }
        else {
            predicate = NSPredicate(format: "%K == nil")
        }
        
        return self.filteredBy(predicate: predicate)
    }
    
    func `where`(format predicateFormat: String, argumentArray arguments: AnyObject[]!) -> Self {
        let predicate = NSPredicate(format: predicateFormat, argumentArray: arguments);
        return self.filteredBy(predicate: predicate)
    }
    
    func `where`(format predicateFormat: String, arguments argList: CVaListPointer) -> Self {
        let predicate = NSPredicate(format: predicateFormat, arguments: argList)
        return self.filteredBy(predicate: predicate)
    }
    
    func `where`(metadataQueryString queryString: String) -> Self {
        let predicate = NSPredicate(fromMetadataQueryString: queryString)
        return self.filteredBy(predicate: predicate)
    }

    func toArray() -> Array<T> {
        self._fetchRequest.fetchBatchSize = self._defaultFetchBatchSize
        
        var results = Array<T>()
        
        self.context.performBlockAndWait { [unowned self] in
            var error: NSError? = nil
            if let objects = self.context.executeFetchRequest(self._fetchRequest, error: &error) as? Array<T> {
                results += objects
            }
        }
        
        return results
    }
    
    func toArray(completion: (Array<T>) -> Void) {
        let context = self.context
        self._fetchRequest.fetchBatchSize = self._defaultFetchBatchSize
        
        let asyncFetchRequest = NSAsynchronousFetchRequest(fetchRequest: self._fetchRequest) { result in
            var results = Array<T>()
            
            if let objects = result.finalResult as? Array<T> {
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
        context.persistentStoreCoordinator.executeRequest(asyncFetchRequest, withContext: context, error: &error)
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
        let context = self.context
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
        context.persistentStoreCoordinator.executeRequest(asyncFetchRequest, withContext: context, error: &error)
    }
    
    func first() -> T? {
        let results = self.take(1).toArray()
        return (results.isEmpty ? nil : results[0])
    }
    
    func first(completion: (T?) -> Void) {
        self.take(1).toArray { results in
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
        return self.take(1).count() > 0
    }
    
    func any(completion: (Bool) -> Void) {
        return self.take(1).count { count in
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
