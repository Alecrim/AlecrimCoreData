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
    
    public func sort<A: AttributeType>(usingAttribute attribute: A, ascending: Bool = true) -> Self {
        return self.sort(usingAttributeName: attribute.___name, ascending: ascending, options: attribute.___comparisonPredicateOptions)
    }
    
    public func sort(usingAttributeName attributeName: String, ascending: Bool = true, options: NSComparisonPredicateOptions = NSComparisonPredicateOptions()) -> Self {
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
        
        return self.sort(usingSortDescriptor: sortDescriptor)
    }
    
    public func sort(usingSortDescriptor sortDescriptor: NSSortDescriptor) -> Self {
        var clone = self
        
        if clone.sortDescriptors != nil {
            clone.sortDescriptors!.append(sortDescriptor)
        }
        else {
            clone.sortDescriptors = [sortDescriptor]
        }
        
        return clone
    }
    
    public func sort(usingSortDescriptors sortDescriptors: [NSSortDescriptor]) -> Self {
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

// MARK - filtering

extension Queryable {
    
    public func filter(usingPredicate predicate: NSPredicate) -> Self {
        var clone = self
        
        if let existingPredicate = clone.predicate {
            clone.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [existingPredicate, predicate])
        }
        else {
            clone.predicate = predicate
        }
        
        return clone
    }
    
}
