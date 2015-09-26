//
//  AttributeQueryType.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-08-08.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public protocol AttributeQueryType: CoreDataQueryable {
    
    var returnsDistinctResults: Bool { get set }
    var propertiesToFetch: [String] { get set }
    
}

// MARK: -

extension AttributeQueryType {
    
    public func distinct() -> Self {
        var clone = self
        clone.returnsDistinctResults = true
        
        return self
    }
    
}

// MARK: - GenericQueryable

extension AttributeQueryType {
    
    public func toArray() -> [Self.Item] {
        do {
            var results: [Self.Item] = []
            
            let fetchRequestResult = try self.dataContext.executeFetchRequest(self.toFetchRequest())
            guard let dicts = fetchRequestResult as? [NSDictionary] else { throw AlecrimCoreDataError.UnexpectedValue(value: fetchRequestResult) }
            
            try dicts.forEach {
                guard $0.count == 1, let value = $0.allValues.first as? Self.Item else {
                    throw AlecrimCoreDataError.UnexpectedValue(value: $0)
                }
                
                results.append(value)
            }
            
            return results
        }
        catch let error {
            AlecrimCoreDataError.handleError(error)
        }
    }
    
}

extension AttributeQueryType where Self.Item: NSDictionary {
    
    public func toArray() -> [NSDictionary] {
        do {
            let fetchRequestResult = try self.dataContext.executeFetchRequest(self.toFetchRequest())
            guard let dicts = fetchRequestResult as? [NSDictionary] else { throw AlecrimCoreDataError.UnexpectedValue(value: fetchRequestResult) }
            
            return dicts
        }
        catch let error {
            AlecrimCoreDataError.handleError(error)
        }
    }
    
}


// MARK: - CoreDataQueryable

extension AttributeQueryType {
    
    public func toFetchRequest() -> NSFetchRequest {
        let fetchRequest = NSFetchRequest()
        
        fetchRequest.entity = self.entityDescription
        
        fetchRequest.fetchOffset = self.offset
        fetchRequest.fetchLimit = self.limit
        fetchRequest.fetchBatchSize = (self.limit > 0 && self.batchSize > self.limit ? 0 : self.batchSize)
        
        fetchRequest.predicate = self.predicate
        fetchRequest.sortDescriptors = self.sortDescriptors
        
        //
        fetchRequest.resultType = .DictionaryResultType
        fetchRequest.returnsDistinctResults = self.returnsDistinctResults
        fetchRequest.propertiesToFetch = self.propertiesToFetch
        
        //
        return fetchRequest
    }
    
}

