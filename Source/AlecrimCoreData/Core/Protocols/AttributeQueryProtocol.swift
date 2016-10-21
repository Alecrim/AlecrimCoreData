//
//  AttributeQueryProtocol.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-08-08.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public protocol AttributeQueryProtocol: CoreDataQueryable {
    
    var returnsDistinctResults: Bool { get set }
    var propertiesToFetch: [String] { get set }
    
}

// MARK: -

extension AttributeQueryProtocol {
    
    public func distinct() -> Self {
        var clone = self
        clone.returnsDistinctResults = true
        
        return self
    }
    
}

// MARK: - GenericQueryable

extension AttributeQueryProtocol {
    
    public func execute() -> [Self.Element] {
        do {
            let fetchRequest = self.toFetchRequest() as NSFetchRequest<NSDictionary>
            fetchRequest.resultType = NSFetchRequestResultType.dictionaryResultType
            
            var results: [Self.Element] = []

            let dicts: [NSDictionary] = try self.context.fetch(fetchRequest)
            
            try dicts.forEach {
                guard $0.count == 1, let value = $0.allValues.first as? Self.Element else {
                    throw AlecrimCoreDataError.unexpectedValue($0)
                }
                
                results.append(value)
            }
            
            return results
        }
        catch {
            AlecrimCoreDataError.handleError(error)
        }
    }
    
}

extension AttributeQueryProtocol where Self.Element: NSDictionary {
    
    public func execute() -> [Self.Element] {
        do {
            return try self.context.fetch(self.toFetchRequest() as NSFetchRequest<Self.Element>)
        }
        catch {
            AlecrimCoreDataError.handleError(error)
        }
    }
    
}


// MARK: - CoreDataQueryable

extension AttributeQueryProtocol where Self.Element: NSDictionary {
    
    public final func toFetchRequest<ResultType: NSFetchRequestResult>() -> NSFetchRequest<ResultType> {
        let fetchRequest = NSFetchRequest<ResultType>()
        
        fetchRequest.entity = self.entityDescription
        
        fetchRequest.fetchOffset = self.offset
        fetchRequest.fetchLimit = self.limit
        fetchRequest.fetchBatchSize = (self.limit > 0 && self.batchSize > self.limit ? 0 : self.batchSize)
        
        fetchRequest.predicate = self.predicate
        fetchRequest.sortDescriptors = self.sortDescriptors
        
        //
        fetchRequest.resultType = .dictionaryResultType
        fetchRequest.returnsDistinctResults = self.returnsDistinctResults
        fetchRequest.propertiesToFetch = self.propertiesToFetch
        
        //
        return fetchRequest
    }
    
}

