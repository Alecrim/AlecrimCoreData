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

public struct FetchRequest<Entity: ManagedObject>: Queryable {

    public typealias Element = Entity

    public fileprivate(set) var offset: Int = 0
    public fileprivate(set) var limit: Int = 0
    public fileprivate(set) var batchSize: Int = Config.defaultBatchSize

    public fileprivate(set) var predicate: Predicate<Entity>? = nil
    public fileprivate(set) var sortDescriptors: [SortDescriptor<Entity>]? = nil

    public init() {
    }

    public func toRaw<Result: NSFetchRequestResult>() -> NSFetchRequest<Result> {
        let entityDescription = Entity.entity()
        let rawValue = NSFetchRequest<Result>(entityName: entityDescription.name!)

        rawValue.entity = entityDescription

        rawValue.fetchOffset = self.offset
        rawValue.fetchLimit = self.limit
        rawValue.fetchBatchSize = (self.limit > 0 && self.batchSize > self.limit ? 0 : self.batchSize)

        rawValue.predicate = self.predicate?.rawValue
        rawValue.sortDescriptors = self.sortDescriptors?.map { $0.rawValue }

        return rawValue
    }

    internal func reversed() -> FetchRequest<Entity> {
        guard let existingSortDescriptors = self.sortDescriptors, !existingSortDescriptors.isEmpty else {
            return self
        }

        var clone = self
        clone.sortDescriptors = existingSortDescriptors.map { SortDescriptor(key: $0.key, ascending: !$0.ascending) }

        return clone
    }

}

// MARK: -

extension FetchRequest {

    public func dropFirst(_ n: Int) -> FetchRequest<Entity> {
        var clone = self
        clone.offset = offset

        return clone
    }

    public func prefix(_ maxLength: Int) -> FetchRequest<Entity> {
        var clone = self
        clone.limit = limit

        return clone
    }

    public func batchSize(_ batchSize: Int) -> FetchRequest<Entity> {
        var clone = self
        clone.batchSize = batchSize

        return clone
    }

}

// MARK: -

extension FetchRequest {

    public func filtered(using predicate: Predicate<Entity>) -> FetchRequest<Entity> {
        var clone = self

        if let existingPredicate = clone.predicate {
            clone.predicate = CompoundPredicate<Entity>(andPredicateWithSubpredicates: [existingPredicate, predicate])
        }
        else {
            clone.predicate = predicate
        }

        return clone
    }

}

// MARK: -

extension FetchRequest {

    public func sorted(by sortDescriptor: SortDescriptor<Entity>) -> FetchRequest<Entity> {
        var clone = self

        if clone.sortDescriptors != nil {
            clone.sortDescriptors!.append(sortDescriptor)
        }
        else {
            clone.sortDescriptors = [sortDescriptor]
        }

        return clone
    }


    public func sorted(by sortDescriptors: [SortDescriptor<Entity>]) -> FetchRequest<Entity> {
        var clone = self

        if clone.sortDescriptors != nil {
            clone.sortDescriptors! += sortDescriptors
        }
        else {
            clone.sortDescriptors = sortDescriptors
        }

        return clone
    }

    public func sorted(by sortDescriptors: SortDescriptor<Entity>...) -> FetchRequest<Entity> {
        var clone = self

        if clone.sortDescriptors != nil {
            clone.sortDescriptors! += sortDescriptors
        }
        else {
            clone.sortDescriptors = sortDescriptors
        }

        return clone
    }

}


