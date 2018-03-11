//
//  FetchRequest.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 11/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// MARK: -

public struct FetchRequest<Entity: ManagedObject> {
    
    public fileprivate(set) var offset: Int = 0
    public fileprivate(set) var limit: Int = 0
    public fileprivate(set) var batchSize: Int = Config.defaultBatchSize
    
    public fileprivate(set) var predicate: Predicate<Entity>? = nil
    public fileprivate(set) var sortDescriptors: [SortDescriptor<Entity>]? = nil
    
    public init() {
    }
    
    public var rawValue: NSFetchRequest<Entity> {
        let entityDescription = Entity.entity()
        let rawValue = NSFetchRequest<Entity>(entityName: entityDescription.name!)
        
        rawValue.entity = entityDescription
        
        rawValue.fetchOffset = self.offset
        rawValue.fetchLimit = self.limit
        rawValue.fetchBatchSize = (self.limit > 0 && self.batchSize > self.limit ? 0 : self.batchSize)
        
        rawValue.predicate = self.predicate?.rawValue
        rawValue.sortDescriptors = self.sortDescriptors?.map { $0.rawValue }
        
        return rawValue
    }

}

// MARK: -

extension FetchRequest {
    
    public func skip(_ offset: Int) -> FetchRequest<Entity> {
        var clone = self
        clone.offset = offset
        
        return clone
    }
    
    public func take(_ limit: Int) -> FetchRequest<Entity> {
        var clone = self
        clone.limit = limit
        
        return clone
    }

    public func setBatchSize(_ batchSize: Int) -> FetchRequest<Entity> {
        var clone = self
        clone.batchSize = batchSize
        
        return clone
    }

}

// MARK: -

extension FetchRequest {

    public func filter(using predicate: Predicate<Entity>) -> FetchRequest<Entity> {
        var clone = self
        
        if let existingPredicate = clone.predicate {
            clone.predicate = CompoundPredicate<Entity>(andPredicateWithSubpredicates: [existingPredicate, predicate])
        }
        else {
            clone.predicate = predicate
        }
        
        return clone
    }

    public func filter(using rawValue: NSPredicate) -> FetchRequest<Entity> {
        return self.filter(using: Predicate<Entity>(rawValue: rawValue))
    }
    
    //
    
    public func `where`(_ closure: () -> Predicate<Entity>) -> FetchRequest<Entity> {
        return self.filter(using: closure())
    }
    
}

// MARK: -

extension FetchRequest {

    public func sort(by sortDescriptor: SortDescriptor<Entity>) -> FetchRequest<Entity> {
        var clone = self
        
        if clone.sortDescriptors != nil {
            clone.sortDescriptors!.append(sortDescriptor)
        }
        else {
            clone.sortDescriptors = [sortDescriptor]
        }

        return clone
    }
    
    public func sort(by rawValue: NSSortDescriptor) -> FetchRequest<Entity> {
        return self.sort(by: SortDescriptor<Entity>(rawValue: rawValue))
    }

    public func sort(by sortDescriptors: [SortDescriptor<Entity>]) -> FetchRequest<Entity> {
        var clone = self
        
        if clone.sortDescriptors != nil {
            clone.sortDescriptors! += sortDescriptors
        }
        else {
            clone.sortDescriptors = sortDescriptors
        }

        return clone
    }

    public func sort(by rawValues: [NSSortDescriptor]) -> FetchRequest<Entity> {
        return self.sort(by: rawValues.map { SortDescriptor<Entity>(rawValue: $0) })
    }
    
    public func sort(by sortDescriptors: SortDescriptor<Entity>...) -> FetchRequest<Entity> {
        var clone = self
        
        if clone.sortDescriptors != nil {
            clone.sortDescriptors! += sortDescriptors
        }
        else {
            clone.sortDescriptors = sortDescriptors
        }
        
        return clone
    }
    
    public func sort(by rawValues: NSSortDescriptor...) -> FetchRequest<Entity> {
        return self.sort(by: rawValues.map { SortDescriptor<Entity>(rawValue: $0) })
    }

    //

    public func sort<Value>(by closure: @autoclosure () -> KeyPath<Entity, Value>) -> FetchRequest<Entity> {
        let sortDescriptor: SortDescriptor<Entity> = .ascending(closure())
        return self.sort(by: sortDescriptor)
    }
    
    //
    
    public func orderBy(_ closure: () -> SortDescriptor<Entity>) -> FetchRequest<Entity> {
        return self.sort(by: closure())
    }
    
    public func orderBy<Value>(_ closure: () -> KeyPath<Entity, Value>) -> FetchRequest<Entity> {
        return self.sort(by: closure())
    }

}

