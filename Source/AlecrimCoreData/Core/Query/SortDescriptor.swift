//
//  SortDescriptor.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 11/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public final class SortDescriptor<Entity: ManagedObject> {

    // MARK: -
    
    public static func ascending(_ key: String) -> SortDescriptor<Entity> {
        return SortDescriptor<Entity>(key: key, ascending: true)
    }

    public static func ascending<Value>(_ keyPath: KeyPath<Entity, Value>) -> SortDescriptor<Entity> {
        return SortDescriptor<Entity>(keyPath: keyPath, ascending: true)
    }

    public static func descending(_ key: String) -> SortDescriptor<Entity> {
        return SortDescriptor<Entity>(key: key, ascending: false)
    }

    public static func descending<Value>(_ keyPath: KeyPath<Entity, Value>) -> SortDescriptor<Entity> {
        return SortDescriptor<Entity>(keyPath: keyPath, ascending: false)
    }

    // MARK: -
    
    public let rawValue: NSSortDescriptor
    
    public let key: String
    public let ascending: Bool
    public let comparisonOptions: NSComparisonPredicate.Options
    
    public convenience init(key: String, ascending: Bool) {
        self.init(rawValue: NSSortDescriptor(key: key, ascending: ascending))
    }
    
    public convenience init<Value>(keyPath: KeyPath<Entity, Value>, ascending: Bool) {
        self.init(rawValue: NSSortDescriptor(keyPath: keyPath, ascending: ascending))
    }

    public init(rawValue: NSSortDescriptor) {
        let comparisonOptions = Config.defaultComparisonOptions

        let selector: Selector?
        
        if comparisonOptions.contains(.caseInsensitive) && comparisonOptions.contains(.diacriticInsensitive) {
            selector = #selector(NSString.localizedCaseInsensitiveCompare(_:))
        }
        else if comparisonOptions.contains(.caseInsensitive) {
            selector = #selector(NSString.caseInsensitiveCompare(_:))
        }
        else if comparisonOptions.contains(.diacriticInsensitive) {
            selector = #selector(NSString.localizedCompare(_:))
        }
        else {
            selector = nil
        }

        // recreate sort descriptor using config options
        self.rawValue = NSSortDescriptor(key: rawValue.key, ascending: rawValue.ascending, selector: selector)
        
        self.key = self.rawValue.key!
        self.ascending = self.rawValue.ascending
        self.comparisonOptions = comparisonOptions
    }

}
