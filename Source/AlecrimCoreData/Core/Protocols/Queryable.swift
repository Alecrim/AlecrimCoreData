//
//  Queryable.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-06-17.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public protocol Queryable: Enumerable {
    
    var predicate: NSPredicate? { get set }
    var sortDescriptors: [NSSortDescriptor]? { get set }
    
}

// MARK - ordering

extension Queryable {
    
    public func sort<A: AttributeType>(attribute attribute: A, ascending: Bool = true) -> Self {
        return self.sort(attributeName: attribute.___name, ascending: ascending, options: attribute.___comparisonPredicateOptions)
    }
    
    @available(*, unavailable, renamed="sort")
    public func sortByAttribute<A: AttributeType>(attribute: A, ascending: Bool = true) -> Self {
        fatalError()
    }

    public func sort(attributeName attributeName: String, ascending: Bool = true, options: NSComparisonPredicateOptions = NSComparisonPredicateOptions()) -> Self {
        let sortDescriptor: NSSortDescriptor
        
        if options.contains(.CaseInsensitivePredicateOption) && options.contains(.DiacriticInsensitivePredicateOption) {
            sortDescriptor = NSSortDescriptor(key: attributeName, ascending: ascending, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        }
        else if options.contains(.CaseInsensitivePredicateOption) {
            sortDescriptor = NSSortDescriptor(key: attributeName, ascending: ascending, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        }
        else if options.contains(.DiacriticInsensitivePredicateOption) {
            sortDescriptor = NSSortDescriptor(key: attributeName, ascending: ascending, selector: #selector(NSString.localizedCompare(_:)))
        }
        else {
            sortDescriptor = NSSortDescriptor(key: attributeName, ascending: ascending)
        }
        
        return self.sort(sortDescriptor: sortDescriptor)
    }
    
    @available(*, unavailable, renamed="sort")
    public func sortByAttributeName(attributeName: String, ascending: Bool = true, options: NSComparisonPredicateOptions = NSComparisonPredicateOptions()) -> Self {
        fatalError()
    }

    public func sort(sortDescriptor sortDescriptor: NSSortDescriptor) -> Self {
        var clone = self
        
        if clone.sortDescriptors != nil {
            clone.sortDescriptors!.append(sortDescriptor)
        }
        else {
            clone.sortDescriptors = [sortDescriptor]
        }
        
        return clone
    }
    
    @available(*, unavailable, renamed="sort")
    public func sortUsingSortDescriptor(sortDescriptor: NSSortDescriptor) -> Self {
        fatalError()
    }

    public func sort(sortDescriptors sortDescriptors: [NSSortDescriptor]) -> Self {
        var clone = self

        if clone.sortDescriptors != nil {
            clone.sortDescriptors! += sortDescriptors
        }
        else {
            clone.sortDescriptors = sortDescriptors
        }
        
        return clone
    }
    
    @available(*, unavailable, renamed="sort")
    public func sortUsingSortDescriptors(sortDescriptors: [NSSortDescriptor]) -> Self {
        fatalError()
    }

}

// MARK - filtering

extension Queryable {
    
    public func filter(predicate predicate: NSPredicate) -> Self {
        var clone = self
        
        if let existingPredicate = clone.predicate {
            clone.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [existingPredicate, predicate])
        }
        else {
            clone.predicate = predicate
        }
        
        return clone
    }
    
    @available(*, unavailable, renamed="filter")
    public func filterUsingPredicate(predicate: NSPredicate) -> Self {
        fatalError()
    }
    
}
