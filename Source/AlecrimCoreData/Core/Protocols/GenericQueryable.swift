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
    
    @available(*, unavailable, renamed="orderBy")
    public func orderByAscending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Self.Item.Type) -> A) -> Self {
        fatalError()
    }
    
    @available(*, unavailable, renamed="orderBy")
    public func orderByDescending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Self.Item.Type) -> A) -> Self {
        fatalError()
    }
    
}

extension GenericQueryable {
    
    public func orderBy<A: AttributeType, V where A.ValueType == V>(ascending: Bool = true, @noescape orderingClosure: (Self.Item.Type) -> A) -> Self {
        return self.sort(attribute: orderingClosure(Self.Item.self), ascending: ascending)
    }
    
    @available(*, unavailable, renamed="orderBy")
    public func orderBy<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Self.Item.Type) -> A) -> Self {
        fatalError()
    }
    
    @available(*, unavailable, renamed="orderBy")
    public func thenBy<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Self.Item.Type) -> A) -> Self {
        fatalError()
    }
    
    @available(*, unavailable, renamed="orderBy")
    public func thenByAscending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Self.Item.Type) -> A) -> Self {
        fatalError()
    }
    
    @available(*, unavailable, renamed="orderBy")
    public func thenByDescending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Self.Item.Type) -> A) -> Self {
        fatalError()
    }
    
}

// MARK: - filtering

extension GenericQueryable {
    
    public func filter(@noescape predicateClosure: (Self.Item.Type) -> NSPredicate) -> Self {
        return self.filter(predicate: predicateClosure(Self.Item.self))
    }
    
}

// MARK: -

extension GenericQueryable {
    
    public func count(@noescape predicateClosure: (Self.Item.Type) -> NSPredicate) -> Int {
        return self.filter(predicate: predicateClosure(Self.Item.self)).count()
    }
    
}

extension GenericQueryable {
    
    public func any(@noescape predicateClosure: (Self.Item.Type) -> NSPredicate) -> Bool {
        return self.filter(predicate: predicateClosure(Self.Item.self)).any()
    }
    
    public func none(@noescape predicateClosure: (Self.Item.Type) -> NSPredicate) -> Bool {
        return self.filter(predicate: predicateClosure(Self.Item.self)).none()
    }
    
}

extension GenericQueryable {
    
    public func first(@noescape predicateClosure: (Self.Item.Type) -> NSPredicate) -> Self.Item? {
        return self.filter(predicate: predicateClosure(Self.Item.self)).first()
    }
    
}

// MARK: - entity

extension GenericQueryable {
    
    public func first() -> Self.Item? {
        return self.take(1).toArray().first
    }
    
}


//// TODO: this crashes the compiler (Xcode 7.3 beta 2)
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

extension Table: SequenceType {

    public typealias Generator = AnyGenerator<T>

    public func generate() -> Generator {
        return AnyGenerator(self.toArray().generate())
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
        return AnyGenerator(self.toArray().generate())
    }

    // turns the SequenceType implementation unavailable
    @available(*, unavailable)
    public func filter(@noescape includeElement: (AttributeQuery.Generator.Element) throws -> Bool) rethrows -> [AttributeQuery.Generator.Element] {
        return []
    }

}

