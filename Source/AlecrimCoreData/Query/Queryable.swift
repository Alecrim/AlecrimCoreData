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
    
    func skip(_ offset: Int) -> Self
    func take(_ limit: Int) -> Self
    func setBatchSize(_ batchSize: Int) -> Self
    
    func filter(using predicate: Predicate<Element>) -> Self
    
    func sort(by sortDescriptor: SortDescriptor<Element>) -> Self
    func sort(by sortDescriptors: [SortDescriptor<Element>]) -> Self
    func sort(by sortDescriptors: SortDescriptor<Element>...) -> Self
    
}

// MARK: -

extension Queryable {

    public func filter(using rawValue: NSPredicate) -> Self {
        return self.filter(using: Predicate<Element>(rawValue: rawValue))
    }
    
    public func `where`(_ closure: () -> Predicate<Element>) -> Self {
        return self.filter(using: closure())
    }

}

extension Queryable {
    
    public func sort(by rawValue: NSSortDescriptor) -> Self {
        return self.sort(by: SortDescriptor<Element>(rawValue: rawValue))
    }

    public func sort(by rawValues: [NSSortDescriptor]) -> Self {
        return self.sort(by: rawValues.map { SortDescriptor<Element>(rawValue: $0) })
    }

    public func sort(by rawValues: NSSortDescriptor...) -> Self {
        return self.sort(by: rawValues.map { SortDescriptor<Element>(rawValue: $0) })
    }

}

extension Queryable {
    
    // so we can write `sort(by: \.name)` instead of `sort(by: \Customer.name)`
    
    public func sort<Value>(by closure: @autoclosure () -> KeyPath<Element, Value>) -> Self {
        let sortDescriptor: SortDescriptor<Element> = .ascending(closure())
        return self.sort(by: sortDescriptor)
    }
    
    // aliases
    
    public func orderBy(_ closure: () -> SortDescriptor<Element>) -> Self {
        return self.sort(by: closure())
    }
    
    public func orderBy<Value>(_ closure: () -> KeyPath<Element, Value>) -> Self {
        return self.sort(by: closure())
    }

}
