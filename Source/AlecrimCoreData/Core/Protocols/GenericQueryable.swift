//
//  GenericQueryable.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-25.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public protocol GenericQueryable: Queryable {
    
    typealias Item
    
    func toArray() -> [Item]

}

// MARK: - ordering

extension GenericQueryable {
    
    public func orderByAscending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Self.Item.Type) -> A) -> Self {
        return self.sortByAttribute(orderingClosure(Self.Item.self), ascending: true)
    }
    
    public func orderByDescending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Self.Item.Type) -> A) -> Self {
        return self.sortByAttribute(orderingClosure(Self.Item.self), ascending: false)
    }
    
}

extension GenericQueryable {
    
    public func orderBy<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Self.Item.Type) -> A) -> Self {
        return self.orderByAscending(orderingClosure)
    }
    
    public func thenBy<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Self.Item.Type) -> A) -> Self {
        return self.orderByAscending(orderingClosure)
    }
    
    public func thenByAscending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Self.Item.Type) -> A) -> Self {
        return self.orderByAscending(orderingClosure)
    }
    
    public func thenByDescending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Self.Item.Type) -> A) -> Self {
        return self.orderByDescending(orderingClosure)
    }
    
}

// MARK: - filtering

extension GenericQueryable {
    
    public func filter(@noescape predicateClosure: (Self.Item.Type) -> NSPredicate) -> Self {
        return self.filterUsingPredicate(predicateClosure(Self.Item.self))
    }
    
}

// MARK: -

extension GenericQueryable {
    
    public func count(@noescape predicateClosure: (Self.Item.Type) -> NSPredicate) -> Int {
        return self.filterUsingPredicate(predicateClosure(Self.Item.self)).count()
    }
    
}

extension GenericQueryable {
    
    public func any(@noescape predicateClosure: (Self.Item.Type) -> NSPredicate) -> Bool {
        return self.filterUsingPredicate(predicateClosure(Self.Item.self)).any()
    }
    
    public func none(@noescape predicateClosure: (Self.Item.Type) -> NSPredicate) -> Bool {
        return self.filterUsingPredicate(predicateClosure(Self.Item.self)).none()
    }
    
}

extension GenericQueryable {
    
    public func first(@noescape predicateClosure: (Self.Item.Type) -> NSPredicate) -> Self.Item? {
        return self.filterUsingPredicate(predicateClosure(Self.Item.self)).first()
    }
    
}

// MARK: - entity

extension GenericQueryable {
    
    public func first() -> Self.Item? {
        return self.take(1).toArray().first
    }
    
}

// TODO: this crashes the compiler (Xcode 7.0 beta 6)
//// MARK: - SequenceType
//
//extension GenericQueryable {
//    
//    public typealias Generator = AnyGenerator<Self.Item>
//    
//    public func generate() -> AnyGenerator<Self.Item> {
//        return anyGenerator(self.toArray().generate())
//    }
//    
//}
//
//

extension Table: SequenceType {

    public typealias Generator = AnyGenerator<T>

    public func generate() -> Generator {
        return anyGenerator(self.toArray().generate())
    }
    
    // turns the SequenceType implementation unavailable
    @available(*, unavailable)
    public func filter(@noescape includeElement: (Table.Generator.Element) throws -> Bool) rethrows -> [Table.Generator.Element] {
        return []
    }
    
}

extension AttributeQuery: SequenceType {
    
    public typealias Generator = AnyGenerator<T>
    
    public func generate() -> Generator {
        return anyGenerator(self.toArray().generate())
    }

    // turns the SequenceType implementation unavailable
    @available(*, unavailable)
    public func filter(@noescape includeElement: (AttributeQuery.Generator.Element) throws -> Bool) rethrows -> [AttributeQuery.Generator.Element] {
        return []
    }

}

