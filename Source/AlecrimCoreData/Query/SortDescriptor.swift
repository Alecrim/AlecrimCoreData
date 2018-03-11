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
    
    public convenience init(key: String, ascending: Bool) {
        self.init(rawValue: NSSortDescriptor(key: key, ascending: ascending))
    }
    
    public convenience init<Value>(keyPath: KeyPath<Entity, Value>, ascending: Bool) {
        self.init(rawValue: NSSortDescriptor(keyPath: keyPath, ascending: ascending))
    }

    public init(rawValue: NSSortDescriptor) {
        self.rawValue = rawValue
        self.key = rawValue.key!
        self.ascending = rawValue.ascending
    }

}
