//
//  GenericQueryable.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-25.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public protocol GenericQueryable: Queryable {
    
    associatedtype Element = Self.Iterator.Element
    
    func execute() -> [Self.Element]

}

// MARK: - ordering

extension GenericQueryable {
    
    public final func orderBy<A: AttributeProtocol, V>(ascending: Bool = true, _ orderingClosure: (Self.Element.Type) -> A) -> Self where A.ValueType == V {
        return self.sort(using: orderingClosure(Self.Element.self), ascending: ascending)
    }
    
    // convenience methods
    
    public final func orderByAscending<A: AttributeProtocol, V>(_ orderingClosure: (Self.Element.Type) -> A) -> Self where A.ValueType == V {
        return self.orderBy(ascending: true, orderingClosure)
    }

    public final func orderByDescending<A: AttributeProtocol, V>(_ orderingClosure: (Self.Element.Type) -> A) -> Self where A.ValueType == V {
        return self.orderBy(ascending: false, orderingClosure)
    }
    
    public final func thenBy<A: AttributeProtocol, V>(ascending: Bool = true, _ orderingClosure: (Self.Element.Type) -> A) -> Self where A.ValueType == V {
        return self.orderBy(ascending: ascending, orderingClosure)
    }

    public final func thenByAscending<A: AttributeProtocol, V>(_ orderingClosure: (Self.Element.Type) -> A) -> Self where A.ValueType == V {
        return self.orderBy(ascending: true, orderingClosure)
    }
    
    public final func thenByDescending<A: AttributeProtocol, V>(_ orderingClosure: (Self.Element.Type) -> A) -> Self where A.ValueType == V {
        return self.orderBy(ascending: false, orderingClosure)
    }
    
}

// MARK: - filtering

extension GenericQueryable {
    
    public final func filter(_ predicateClosure: (Self.Element.Type) -> NSPredicate) -> Self {
        return self.filter(using: predicateClosure(Self.Element.self))
    }
    
}

// MARK: -

extension GenericQueryable {
    
    public final func count(_ predicateClosure: (Self.Element.Type) -> NSPredicate) -> Int {
        return self.filter(using: predicateClosure(Self.Element.self)).count()
    }
    
}

extension GenericQueryable {
    
    public final func any(_ predicateClosure: (Self.Element.Type) -> NSPredicate) -> Bool {
        return self.filter(using: predicateClosure(Self.Element.self)).any()
    }
    
    public final func none(_ predicateClosure: (Self.Element.Type) -> NSPredicate) -> Bool {
        return self.filter(using: predicateClosure(Self.Element.self)).none()
    }
    
}

extension GenericQueryable {
    
    public final func first(_ predicateClosure: (Self.Element.Type) -> NSPredicate) -> Self.Element? {
        return self.filter(using: predicateClosure(Self.Element.self)).first()
    }
    
}

// MARK: - entity

extension GenericQueryable {
    
    public final func first() -> Self.Element? {
        return self.take(1).execute().first
    }
    
}

// MARK: - Sequence

extension GenericQueryable {
    
    public final func makeIterator() -> AnyIterator<Self.Element> {
        return AnyIterator(self.execute().makeIterator())
    }
    
}
