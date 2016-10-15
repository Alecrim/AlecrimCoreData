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
    
    public final func sort<A: AttributeProtocol>(using attribute: A, ascending: Bool = true) -> Self {
        return self.sort(usingAttributeName: attribute.___name, ascending: ascending, options: attribute.___comparisonPredicateOptions)
    }
    
    public final func sort(usingAttributeName attributeName: String, ascending: Bool = true, options: NSComparisonPredicate.Options = PersistentContainerOptions.defaultComparisonPredicateOptions) -> Self {
        let sortDescriptor: NSSortDescriptor
        
        if options.contains(.caseInsensitive) && options.contains(.diacriticInsensitive) {
            sortDescriptor = NSSortDescriptor(key: attributeName, ascending: ascending, selector: #selector(NSString.localizedCaseInsensitiveCompare(_:)))
        }
        else if options.contains(.caseInsensitive) {
            sortDescriptor = NSSortDescriptor(key: attributeName, ascending: ascending, selector: #selector(NSString.caseInsensitiveCompare(_:)))
        }
        else if options.contains(.diacriticInsensitive) {
            sortDescriptor = NSSortDescriptor(key: attributeName, ascending: ascending, selector: #selector(NSString.localizedCompare(_:)))
        }
        else {
            sortDescriptor = NSSortDescriptor(key: attributeName, ascending: ascending)
        }
        
        return self.sort(using: sortDescriptor)
    }
    
    public final func sort(using sortDescriptor: NSSortDescriptor) -> Self {
        var clone = self
        
        if clone.sortDescriptors != nil {
            clone.sortDescriptors!.append(sortDescriptor)
        }
        else {
            clone.sortDescriptors = [sortDescriptor]
        }
        
        return clone
    }
    
    public final func sort(using sortDescriptors: [NSSortDescriptor]) -> Self {
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
    
    public final func filter(using predicate: NSPredicate) -> Self {
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
