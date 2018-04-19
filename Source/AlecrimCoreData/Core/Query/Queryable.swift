//
//  Queryable.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 11/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// MARK: -

public protocol Queryable {
    
    associatedtype Element: ManagedObject
    
    func dropFirst(_ n: Int) -> Self
    func prefix(_ maxLength: Int) -> Self
    func setBatchSize(_ batchSize: Int) -> Self
    
    func filtered(using predicate: Predicate<Element>) -> Self
    
    func sorted(by sortDescriptor: SortDescriptor<Element>) -> Self
    func sorted(by sortDescriptors: [SortDescriptor<Element>]) -> Self
    func sorted(by sortDescriptors: SortDescriptor<Element>...) -> Self
    
}

// MARK: -

extension Queryable {

    public func filtered(using rawValue: NSPredicate) -> Self {
        return self.filtered(using: Predicate<Element>(rawValue: rawValue))
    }
    
    public func `where`(_ closure: () -> Predicate<Element>) -> Self {
        return self.filtered(using: closure())
    }

}

extension Queryable {
    
    public func sorted(by rawValue: NSSortDescriptor) -> Self {
        return self.sorted(by: SortDescriptor<Element>(rawValue: rawValue))
    }

    public func sorted(by rawValues: [NSSortDescriptor]) -> Self {
        return self.sorted(by: rawValues.map { SortDescriptor<Element>(rawValue: $0) })
    }

    public func sorted(by rawValues: NSSortDescriptor...) -> Self {
        return self.sorted(by: rawValues.map { SortDescriptor<Element>(rawValue: $0) })
    }

}

extension Queryable {
    
    // so we can write `sort(by: \.name)` instead of `sort(by: \Customer.name)`
    
    public func sorted<Value>(by closure: @autoclosure () -> KeyPath<Element, Value>) -> Self {
        let sortDescriptor: SortDescriptor<Element> = .ascending(closure())
        return self.sorted(by: sortDescriptor)
    }
    
    // aliases
    
    public func orderBy(_ closure: () -> SortDescriptor<Element>) -> Self {
        return self.sorted(by: closure())
    }
    
    public func orderBy<Value>(_ closure: () -> KeyPath<Element, Value>) -> Self {
        return self.sorted(by: closure())
    }

}
