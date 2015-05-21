//
//  Query.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-02-27.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public class Query {

    internal let context: Context
    internal let entityName: String

    internal var offset: Int = 0
    internal var limit: Int = 0

    internal var predicate: NSPredicate?
    internal var sortDescriptors: [NSSortDescriptor]?
    
    public required init(context: Context, entityName: String) {
        self.context = context
        self.entityName = entityName
    }
    
    public func toFetchRequest() -> NSFetchRequest {
        let fetchRequest = NSFetchRequest(entityName: self.entityName)
        
        fetchRequest.fetchBatchSize = self.context.contextOptions.fetchBatchSize
        fetchRequest.fetchOffset = self.offset
        fetchRequest.fetchLimit = self.limit
        
        fetchRequest.predicate = self.predicate?.copy() as? NSPredicate
        fetchRequest.sortDescriptors = self.sortDescriptors
        
        return fetchRequest
    }
    
    internal func clone() -> Self {
        var other = self.dynamicType(context: self.context, entityName: self.entityName)
        
        other.offset = self.offset
        other.limit = self.limit

        other.predicate = self.predicate?.copy() as? NSPredicate
        other.sortDescriptors = self.sortDescriptors
        
        return other
    }
    
    internal func executeFetchRequest(fetchRequest: NSFetchRequest) -> [AnyObject]? {
        var executeFetchRequestError: NSError? = nil
        let objects = self.context.executeFetchRequest(fetchRequest, error: &executeFetchRequestError)
        
        return objects
    }

    private func sortDescriptorsFromString(string: String, defaultAscendingValue: Bool) -> [NSSortDescriptor] {
        var sortDescriptors = [NSSortDescriptor]()
        
        let sortKeys = string.componentsSeparatedByString(",") as [String]
        for sortKey in sortKeys {
            var effectiveSortKey = sortKey
            var effectiveAscending = defaultAscendingValue
            var effectiveOptionalParameter: NSString? = nil
            
            let sortComponents = sortKey.componentsSeparatedByString(":") as [String]
            if sortComponents.count > 1 {
                effectiveSortKey = sortComponents[0]
                effectiveAscending = (sortComponents[1] as NSString).boolValue
                
                if (sortComponents.count > 2) {
                    effectiveOptionalParameter = sortComponents[2]
                }
            }
            
            if let eop = effectiveOptionalParameter where eop.rangeOfString("cd").location != NSNotFound {
                sortDescriptors.append(NSSortDescriptor(key: effectiveSortKey, ascending: effectiveAscending, selector: Selector("localizedCaseInsensitiveCompare:")))
            }
            else {
                sortDescriptors.append(NSSortDescriptor(key: effectiveSortKey, ascending: effectiveAscending))
            }
        }
        
        return sortDescriptors
    }
    
}

// MARK: - partitioning

extension Query {
    
    public func skip(count: Int) -> Self {
        let clone = self.clone()
        clone.offset = count
        
        return clone
    }
    
    public func take(count: Int) -> Self {
        let clone = self.clone()
        clone.limit = count
        
        return clone
    }
    
}

// MARK - ordering

extension Query {
    
    public func orderBy(attributeName: String) -> Self {
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func orderByAscending(attributeName: String) -> Self {
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func orderByDescending(attributeName: String) -> Self {
        return self.sortBy(attributeName, ascending: false)
    }
    
    public func thenBy(attributeName: String) -> Self {
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func thenByAscending(attributeName: String) -> Self {
        return self.sortBy(attributeName, ascending: true)
    }
    
    public func thenByDescending(attributeName: String) -> Self {
        return self.sortBy(attributeName, ascending: false)
    }
    
    public func sortBy(sortTerm: String, ascending: Bool = true) -> Self {
        return self.sortBy(sortDescriptors: self.sortDescriptorsFromString(sortTerm, defaultAscendingValue: ascending))
    }
    
    public func sortBy(sortDescriptor addedSortDescriptor: NSSortDescriptor) -> Self {
        return self.sortBy(sortDescriptors: [addedSortDescriptor])
    }
    
    public func sortBy(sortDescriptors addedSortDescriptors: [NSSortDescriptor]) -> Self {
        let clone = self.clone()
        
        if clone.sortDescriptors == nil {
            clone.sortDescriptors = addedSortDescriptors
        }
        else {
            clone.sortDescriptors! += addedSortDescriptors
        }
        
        return clone
    }
    
}

// MARK - restriction

extension Query {
    
    public func filterBy(attribute attributeName: String, value: AnyObject?) -> Self {
        let predicate: NSPredicate

        if let v: AnyObject = value {
            predicate = NSPredicate(format: "%K == %@", argumentArray: [attributeName, v])
        }
        else {
            predicate = NSPredicate(format: "%K == nil", argumentArray: [attributeName])
        }
        
        return self.filterBy(predicate: predicate)
    }
    
    public func filterBy(#predicateFormat: String, argumentArray arguments: [AnyObject]?) -> Self {
        let predicate = NSPredicate(format: predicateFormat, argumentArray: arguments)
        return self.filterBy(predicate: predicate)
    }
    
    public func filterBy(#predicateFormat: String, arguments: AnyObject...) -> Self {
        let predicate = NSPredicate(format: predicateFormat, argumentArray: arguments)
        return self.filterBy(predicate: predicate)
    }
    
    public func filterBy(#predicateFormat: String, arguments: CVaListPointer) -> Self {
        let predicate = NSPredicate(format: predicateFormat, arguments: arguments)
        return self.filterBy(predicate: predicate)
    }
    
    public func filterBy(#predicate: NSPredicate) -> Self {
        let clone = self.clone()
        
        if clone.predicate == nil {
            clone.predicate = predicate
        }
        else if let compoundPredicate = clone.predicate as? NSCompoundPredicate {
            var subpredicates = compoundPredicate.subpredicates as! [NSPredicate]
            subpredicates.append(predicate)
            clone.predicate = NSCompoundPredicate.andPredicateWithSubpredicates(subpredicates)
        }
        else {
            let subpredicates = [clone.predicate!, predicate]
            clone.predicate = NSCompoundPredicate.andPredicateWithSubpredicates(subpredicates)
        }
        
        return clone
    }

}

// MARK: - aggregate

extension Query {
    
    public func count() -> Int {
        let fetchRequest = self.toFetchRequest()
        var c = 0
        
        self.context.managedObjectContext.performBlockAndWait {
            var error: NSError? = nil
            c += self.context.managedObjectContext.countForFetchRequest(fetchRequest, error: &error)
        }
        
        return c
    }
    
}

// MARK: - quantifiers

extension Query {
    
    public func any() -> Bool {
        let fetchRequest = self.toFetchRequest()
        fetchRequest.fetchLimit = 1

        var c = 0
        
        self.context.managedObjectContext.performBlockAndWait {
            var error: NSError? = nil
            c += self.context.managedObjectContext.countForFetchRequest(fetchRequest, error: &error)
        }
        
        return c > 0
    }
    
}


