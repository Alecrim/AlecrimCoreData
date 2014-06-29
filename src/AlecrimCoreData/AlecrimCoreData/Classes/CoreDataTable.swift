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
    
    let dataModel: CoreDataModel
    
    init(dataModel: CoreDataModel) {
        self.dataModel = dataModel
    }
    
//    deinit {
//        println("deinit - CoreDataTable")
//    }
    
    // #pragma mark - private
    
    let _defaultFetchBatchSize = 20
    @lazy var _underlyingFetchRequest = NSFetchRequest(entityName: T.getEntityName())
    
}

extension CoreDataTable {

    func skip(count: Int) -> Self {
        self._underlyingFetchRequest.fetchOffset = count
        return self
    }
    
    func take(count: Int) -> Self {
        self._underlyingFetchRequest.fetchLimit = count
        return self
    }

    func sortedBy(sortTerm: String, ascending: Bool = true) -> Self {
        if self._underlyingFetchRequest.sortDescriptors == nil {
            self._underlyingFetchRequest.sortDescriptors = self._sortDescriptorsFromString(sortTerm, defaultAscendingValue: ascending)
        }
        else {
            var sortDescriptors = self._underlyingFetchRequest.sortDescriptors.copy()
            sortDescriptors += self._sortDescriptorsFromString(sortTerm, defaultAscendingValue: ascending)
            self._underlyingFetchRequest.sortDescriptors = sortDescriptors
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
        if self._underlyingFetchRequest.predicate == nil {
            self._underlyingFetchRequest.predicate = predicate
        }
        else if let compoundPredicate = self._underlyingFetchRequest.predicate as? NSCompoundPredicate {
            var subpredicates = compoundPredicate.subpredicates.copy()
            subpredicates += predicate
            self._underlyingFetchRequest.predicate = NSCompoundPredicate.andPredicateWithSubpredicates(subpredicates)
        }
        else {
            let subpredicates = [ self._underlyingFetchRequest.predicate!, predicate ]
            self._underlyingFetchRequest.predicate = NSCompoundPredicate.andPredicateWithSubpredicates(subpredicates)
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
    
}

extension CoreDataTable {

    func toArray() -> T[] {
        return self._toArray(fetchRequest: self._underlyingFetchRequest.copy() as NSFetchRequest)
    }
    
    func toArray(completion: (T[]) -> Void) {
        self._toArray(fetchRequest: self._underlyingFetchRequest.copy() as NSFetchRequest, completion: completion)
    }

    func count() -> Int {
        return self._count(fetchRequest: self._underlyingFetchRequest.copy() as NSFetchRequest)
    }

    func count(completion: (Int) -> Void) {
        self._count(fetchRequest: self._underlyingFetchRequest.copy() as NSFetchRequest)
    }

    func first() -> T? {
        let fetchRequest = self._underlyingFetchRequest.copy() as NSFetchRequest
        fetchRequest.fetchLimit = 1
        
        let results = self._toArray(fetchRequest: fetchRequest)
        
        return (results.isEmpty ? nil : results[0])
    }
    
    func first(completion: (T?) -> Void) {
        let fetchRequest = self._underlyingFetchRequest.copy() as NSFetchRequest
        fetchRequest.fetchLimit = 1
        
        self._toArray(fetchRequest: fetchRequest) { results in
            completion(results.isEmpty ? nil : results[0])
        }
    }
    
    func any() -> Bool {
        let fetchRequest = self._underlyingFetchRequest.copy() as NSFetchRequest
        fetchRequest.fetchLimit = 1
        
        let result = self._count(fetchRequest: fetchRequest) > 0
        
        return result
    }
    
    func any(completion: (Bool) -> Void) {
        let fetchRequest = self._underlyingFetchRequest.copy() as NSFetchRequest
        fetchRequest.fetchLimit = 1

        return self._count(fetchRequest: fetchRequest) { count in
            completion(count > 0)
        }
    }
    
}

extension CoreDataTable {
    
    func _sortDescriptorsFromString(string: String, defaultAscendingValue: Bool) -> NSSortDescriptor[] {
        var sortDescriptors = NSSortDescriptor[]()
        
        let sortKeys = string.componentsSeparatedByString(",") as NSString[]
        for sortKey in sortKeys {
            var effectiveSortKey = sortKey
            var effectiveAscending = defaultAscendingValue
            var effectiveOptionalParameter: NSString? = nil
            
            let sortComponents = sortKey.componentsSeparatedByString(":") as NSString[]
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
    
    func _toArray(#fetchRequest: NSFetchRequest) -> T[] {
        fetchRequest.fetchBatchSize = self._defaultFetchBatchSize
        
        var results = T[]()
        
        self.dataModel.context.performBlockAndWait { [weak self] in
            if let s = self {
                var error: NSError? = nil
                if let objects = s.dataModel.context.executeFetchRequest(fetchRequest, error: &error) as? T[] {
                    results += objects
                }
            }
        }
        
        return results
    }

    // TODO: verify if it will be possible to use NSAsynchronousFetchRequest in future versions (of AlecrimCoreData and Swift) [see WWDC 2014 - 225]
    func _toArray(#fetchRequest: NSFetchRequest, completion: (T[]) -> Void) {
        fetchRequest.fetchBatchSize = self._defaultFetchBatchSize

        let context = self.dataModel.context
        context.performBlock {
            var results = T[]()

            var error: NSError? = nil
            if let objects = context.executeFetchRequest(fetchRequest, error: &error) as? T[] {
                results += objects
            }
        
            completion(results)
        }
    }
    
    func _count(#fetchRequest: NSFetchRequest) -> Int {
        var c = 0
        
        self.dataModel.context.performBlockAndWait { [weak self] in
            if let s = self {
                var error: NSError? = nil
                c += s.dataModel.context.countForFetchRequest(fetchRequest, error: &error)
            }
        }
        
        return c
    }
    
    // TODO: verify if it will be possible to use NSAsynchronousFetchRequest in future versions (of AlecrimCoreData and Swift) [see WWDC 2014 - 225]
    func _count(#fetchRequest: NSFetchRequest, completion: (Int) -> Void) {
        let context = self.dataModel.context
        context.performBlock {
            var c = 0
            
            var error: NSError? = nil
            c += context.countForFetchRequest(fetchRequest, error: &error)
            
            completion(c)
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
        let entityDescription = NSEntityDescription.entityForName(T.getEntityName(), inManagedObjectContext: self.dataModel.context)
        let managedObject = T(entity: entityDescription, insertIntoManagedObjectContext: self.dataModel.context)
        
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
        if let managedObjectInContext = self.dataModel.context.existingObjectWithID(managedObject.objectID, error: &retrieveExistingObjectError) {
            self.dataModel.context.deleteObject(managedObjectInContext)
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
