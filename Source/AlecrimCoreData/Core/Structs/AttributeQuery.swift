//
//  AttributeQuery.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-04-11.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public struct AttributeQuery<T: NSDictionary>: AttributeQueryProtocol {
    
    public typealias Element = T
    
    public let context: NSManagedObjectContext
    public let entityDescription: NSEntityDescription
    
    public var offset: Int = 0
    public var limit: Int = 0
    public var batchSize: Int = PersistentContainerOptions.defaultBatchSize
    
    public var predicate: NSPredicate? = nil
    public var sortDescriptors: [NSSortDescriptor]? = nil
    
    public var returnsDistinctResults = false
    public var propertiesToFetch = [String]()
    
    fileprivate init(context: NSManagedObjectContext, entityDescription: NSEntityDescription, offset: Int, limit: Int, batchSize: Int, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) {
        self.context = context
        self.entityDescription = entityDescription
        
        self.offset = offset
        self.limit = limit
        self.batchSize = batchSize
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
    }

}

// MARK: - Table extensions

extension Table {
    
    // one attribute
    public func select<P, A: AttributeProtocol>(_ closure: (T.Type) -> A) -> AttributeQuery<P> where A.ValueType == P {
        var attributeQuery = AttributeQuery<P>(
            context: self.context,
            entityDescription: self.entityDescription,
            offset: self.offset,
            limit: self.limit,
            batchSize: self.batchSize,
            predicate: self.predicate,
            sortDescriptors: self.sortDescriptors
        )
        
        attributeQuery.propertiesToFetch.append(closure(T.self).___name)
        
        return attributeQuery
    }

    // more than one attribute
    public func select(_ propertiesToFetch: [String]) -> AttributeQuery<NSDictionary> {
        var attributeQuery = AttributeQuery<NSDictionary>(
            context: self.context,
            entityDescription: self.entityDescription,
            offset: self.offset,
            limit: self.limit,
            batchSize: self.batchSize,
            predicate: self.predicate,
            sortDescriptors: self.sortDescriptors
        )
        
        attributeQuery.propertiesToFetch = propertiesToFetch
        
        return attributeQuery
    }

}
