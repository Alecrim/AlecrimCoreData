//
//  AttributeQuery.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-04-11.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public final class AttributeQuery: Query {
    
    private var propertiesToFetch = [String]()
    private var returnsDistinctResults = false
    
    internal convenience init(previousQuery: Query, propertiesToFetch: [String]) {
        self.init(context: previousQuery.context, entityName: previousQuery.entityName)
        
        self.offset = previousQuery.offset
        self.limit = previousQuery.limit
        
        self.predicate = previousQuery.predicate?.copy() as? NSPredicate
        self.sortDescriptors = previousQuery.sortDescriptors

        self.propertiesToFetch += propertiesToFetch
    }

    override internal func clone() -> Self {
        let other = unsafeBitCast(super.clone(), self.dynamicType)
        
        other.propertiesToFetch = self.propertiesToFetch
        other.returnsDistinctResults = self.returnsDistinctResults
        
        return other
    }
    
}

// MARK: - sequence

extension AttributeQuery: SequenceType {
    
    public typealias GeneratorType = IndexingGenerator<[NSDictionary]>
    
    public func generate() -> GeneratorType {
        return self.toArray().generate()
    }
    
}


// MARK: - conversion

extension AttributeQuery {
    
    public func toArray() -> [NSDictionary] {
        let fetchRequest = self.toFetchRequest()
        fetchRequest.resultType = .DictionaryResultType
        fetchRequest.returnsDistinctResults = self.returnsDistinctResults
        fetchRequest.propertiesToFetch = self.propertiesToFetch
        
        var results = [NSDictionary]()
        
        if let objects = self.executeFetchRequest(fetchRequest) as? [NSDictionary] {
            results += objects
        }
        
        // HAX: ensure distinct results
        if self.returnsDistinctResults {
            let set = NSSet(array: results)
            results = set.allObjects as! [NSDictionary]
        }
        
        
        return results
    }
    
}

// MARK: - fetch parameters

extension AttributeQuery {
    
    public func distinct() -> Self {
        let clone = self.clone()
        clone.returnsDistinctResults = true
        
        return clone
    }
    
}
