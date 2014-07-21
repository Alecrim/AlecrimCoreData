//
//  CoreDataTable.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataTable<T: NSManagedObject> {
    
    // MARK: internal
    internal let dataModel: CoreDataModel
    
    internal let defaultFetchBatchSize = 20
    internal lazy var underlyingFetchRequest = NSFetchRequest(entityName: T.getEntityName())

    // MARK: init and deinit
    public init(dataModel: CoreDataModel) {
        self.dataModel = dataModel
    }
    
}

public extension CoreDataTable {

    public func skip(count: Int) -> Self {
        self.underlyingFetchRequest.fetchOffset = count
        return self
    }
    
    public func take(count: Int) -> Self {
        self.underlyingFetchRequest.fetchLimit = count
        return self
    }

    public func sortBy(sortTerm: String, ascending: Bool = true) -> Self {
        let addedSortDescriptors = self.sortDescriptorsFromString(sortTerm, defaultAscendingValue: ascending)
        
        if var sortDescriptors = self.underlyingFetchRequest.sortDescriptors {
            sortDescriptors += addedSortDescriptors
        }
        else {
            self.underlyingFetchRequest.sortDescriptors = addedSortDescriptors
        }
        
        return self
    }
    
    public func orderBy(attributeName: String) -> Self {
        return self.orderByAscending(attributeName)
    }

    public func orderByAscending(attributeName: String) -> Self {
        return self.sortBy(attributeName, ascending: true)
    }

    public func orderByDescending(attributeName: String) -> Self {
        return self.sortBy(attributeName, ascending: false)
    }

    public func filterBy(#predicate: NSPredicate) -> Self {
        if self.underlyingFetchRequest.predicate == nil {
            self.underlyingFetchRequest.predicate = predicate
        }
        else if let compoundPredicate = self.underlyingFetchRequest.predicate as? NSCompoundPredicate {
            var subpredicates = compoundPredicate.subpredicates as Array<NSPredicate>
            subpredicates += predicate
            self.underlyingFetchRequest.predicate = NSCompoundPredicate.andPredicateWithSubpredicates(subpredicates)
        }
        else {
            let subpredicates = [ self.underlyingFetchRequest.predicate!, predicate ]
            self.underlyingFetchRequest.predicate = NSCompoundPredicate.andPredicateWithSubpredicates(subpredicates)
        }
    
        return self
    }
    
    public func filterBy<V: AnyObject>(attribute attributeName: String, value: V?) -> Self {
        var predicate: NSPredicate
        if let v = value {
            predicate = NSPredicate(format: "%K == %@", argumentArray: [ attributeName, v ])
        }
        else {
            predicate = NSPredicate(format: "%K == nil")
        }
        
        return self.filterBy(predicate: predicate)
    }
    
    public func filterBy(#predicateFormat: String, argumentArray arguments: [AnyObject]!) -> Self {
        let predicate = NSPredicate(format: predicateFormat, argumentArray: arguments);
        return self.filterBy(predicate: predicate)
    }
    
    public func filterBy(#predicateFormat: String, arguments argList: CVaListPointer) -> Self {
        let predicate = NSPredicate(format: predicateFormat, arguments: argList)
        return self.filterBy(predicate: predicate)
    }
    
}

public extension CoreDataTable {

    public func toArray() -> [T] {
        return self.toArray(fetchRequest: self.underlyingFetchRequest.copy() as NSFetchRequest)
    }
    
    public func count() -> Int {
        return self.count(fetchRequest: self.underlyingFetchRequest.copy() as NSFetchRequest)
    }

    public func first() -> T? {
        let fetchRequest = self.underlyingFetchRequest.copy() as NSFetchRequest
        fetchRequest.fetchLimit = 1
        
        let results = self.toArray(fetchRequest: fetchRequest)
        
        return (results.isEmpty ? nil : results[0])
    }
    
    public func any() -> Bool {
        let fetchRequest = self.underlyingFetchRequest.copy() as NSFetchRequest
        fetchRequest.fetchLimit = 1
        
        let result = self.count(fetchRequest: fetchRequest) > 0
        
        return result
    }
    
}

public extension CoreDataTable {

    public func toArray(completion: ([T]) -> Void) {
        self.toArray(fetchRequest: self.underlyingFetchRequest.copy() as NSFetchRequest, completion: completion)
    }

    public func count(completion: (Int) -> Void) {
        self.count(fetchRequest: self.underlyingFetchRequest.copy() as NSFetchRequest, completion: completion)
    }

    public func first(completion: (T?) -> Void) {
        let fetchRequest = self.underlyingFetchRequest.copy() as NSFetchRequest
        fetchRequest.fetchLimit = 1
        
        self.toArray(fetchRequest: fetchRequest) { results in
            completion(results.isEmpty ? nil : results[0])
        }
    }

    public func any(completion: (Bool) -> Void) {
        let fetchRequest = self.underlyingFetchRequest.copy() as NSFetchRequest
        fetchRequest.fetchLimit = 1
        
        return self.count(fetchRequest: fetchRequest) { count in
            completion(count > 0)
        }
    }

}

public extension CoreDataTable {
    
    public func createEntity() -> T {
        let entityDescription = NSEntityDescription.entityForName(T.getEntityName(), inManagedObjectContext: self.dataModel.context)
        let managedObject = T(entity: entityDescription, insertIntoManagedObjectContext: self.dataModel.context)
        
        return managedObject
    }
    
    public func createOrGetFirstEntity<V: AnyObject>(whereAttribute attributeName: String, isEqualTo value: V?) -> T {
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
        if let managedObjectInContext = self.dataModel.context.existingObjectWithID(managedObject.objectID, error: &retrieveExistingObjectError) {
            self.dataModel.context.deleteObject(managedObjectInContext)
            return (managedObject.deleted || managedObject.managedObjectContext == nil, retrieveExistingObjectError)
        }
        else {
            return (false, retrieveExistingObjectError)
        }
    }
    
    public func refreshEntity(managedObject: T) {
        managedObject.managedObjectContext.refreshObject(managedObject, mergeChanges: true)
    }
    
}

extension CoreDataTable: Sequence {
    
    typealias GeneratorType = IndexingGenerator<[T]>
    
    public func generate() -> GeneratorType {
        return self.toArray().generate()
    }
    
}

private extension CoreDataTable {
    
    private func sortDescriptorsFromString(string: String, defaultAscendingValue: Bool) -> [NSSortDescriptor] {
        var sortDescriptors = [NSSortDescriptor]()
        
        let sortKeys = string.componentsSeparatedByString(",") as [NSString]
        for sortKey in sortKeys {
            var effectiveSortKey = sortKey
            var effectiveAscending = defaultAscendingValue
            var effectiveOptionalParameter: NSString? = nil
            
            let sortComponents = sortKey.componentsSeparatedByString(":") as [NSString]
            if sortComponents.count > 1 {
                effectiveSortKey = sortComponents[0]
                effectiveAscending = sortComponents[1].boolValue
                
                if (sortComponents.count > 2) {
                    effectiveOptionalParameter = sortComponents[2]
                }
            }
            
            if effectiveOptionalParameter != nil && effectiveOptionalParameter!.rangeOfString("cd").location != NSNotFound {
                sortDescriptors += NSSortDescriptor(key: effectiveSortKey, ascending: effectiveAscending, selector: "localizedCaseInsensitiveCompare:")
            }
            else {
                sortDescriptors += NSSortDescriptor(key: effectiveSortKey, ascending: effectiveAscending)
            }
        }
        
        return sortDescriptors
    }
    
}

private extension CoreDataTable {

    private func toArray(#fetchRequest: NSFetchRequest) -> [T] {
        fetchRequest.fetchBatchSize = self.defaultFetchBatchSize
        
        var results = [T]()
        
        self.dataModel.context.performBlockAndWait { [weak self] in
            if let s = self {
                var error: NSError? = nil
                if let objects = s.dataModel.context.executeFetchRequest(fetchRequest, error: &error) as? [T] {
                    results += objects
                }
            }
        }
        
        return results
    }

    private func count(#fetchRequest: NSFetchRequest) -> Int {
        var c = 0
        
        self.dataModel.context.performBlockAndWait { [weak self] in
            if let s = self {
                var error: NSError? = nil
                c += s.dataModel.context.countForFetchRequest(fetchRequest, error: &error)
            }
        }
        
        return c
    }
    
}

private extension CoreDataTable {

    // TODO: verify if it will be possible to use NSAsynchronousFetchRequest in future versions (of AlecrimCoreData and Swift) [see WWDC 2014 - 225]
    private func toArray(#fetchRequest: NSFetchRequest, completion: ([T]) -> Void) {
        fetchRequest.fetchBatchSize = self.defaultFetchBatchSize
        
        //        let asyncRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { asyncResult in
        //            var results = [T]()
        //            if let finalResult = asyncResult.finalResult as? [T] {
        //                results += finalResult
        //            }
        //
        //            completion(results)
        //        }
        //
        //        var error: NSError? = nil
        //        self.dataModel.context.persistentStoreCoordinator.executeRequest(asyncRequest, withContext: self.dataModel.context, error: &error)
        //        if error != nil {
        //            completion([T]())
        //        }
        
        let context = self.dataModel.context
        context.performBlock {
            var results = [T]()
            
            var error: NSError? = nil
            if let objects = context.executeFetchRequest(fetchRequest, error: &error) as? [T] {
                results += objects
            }
            
            completion(results)
        }
    }

    // TODO: verify if it will be possible to use NSAsynchronousFetchRequest in future versions (of AlecrimCoreData and Swift) [see WWDC 2014 - 225]
    private func count(#fetchRequest: NSFetchRequest, completion: (Int) -> Void) {
        let context = self.dataModel.context
        context.performBlock {
            var c = 0
            
            var error: NSError? = nil
            c += context.countForFetchRequest(fetchRequest, error: &error)
            
            completion(c)
        }
    }

}
