//
//  GenericQueryable.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-25.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public protocol GenericQueryable: Queryable {
    
    typealias Entity
    
    func toArray() -> [Entity]

}

// MARK: - ordering

extension GenericQueryable {
    
    public func orderByAscending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Entity.Type) -> A) -> Self {
        return self.sortByAttribute(orderingClosure(Entity.self), ascending: true)
    }
    
    public func orderByDescending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Entity.Type) -> A) -> Self {
        return self.sortByAttribute(orderingClosure(Entity.self), ascending: false)
    }
    
}

extension GenericQueryable {
    
    public func orderBy<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Entity.Type) -> A) -> Self {
        return self.orderByAscending(orderingClosure)
    }
    
    public func thenBy<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Entity.Type) -> A) -> Self {
        return self.orderByAscending(orderingClosure)
    }
    
    public func thenByAscending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Entity.Type) -> A) -> Self {
        return self.orderByAscending(orderingClosure)
    }
    
    public func thenByDescending<A: AttributeType, V where A.ValueType == V>(@noescape orderingClosure: (Entity.Type) -> A) -> Self {
        return self.orderByDescending(orderingClosure)
    }
    
}

// MARK: - filtering

extension GenericQueryable {
    
    public func filter(@noescape predicateClosure: (Entity.Type) -> NSPredicate) -> Self {
        return self.filterUsingPredicate(predicateClosure(Entity.self))
    }
    
}

// MARK: -

extension GenericQueryable {
    
    public func count(@noescape predicateClosure: (Entity.Type) -> NSPredicate) -> Int {
        return self.filterUsingPredicate(predicateClosure(Entity.self)).count()
    }
    
}

extension GenericQueryable {
    
    public func any(@noescape predicateClosure: (Entity.Type) -> NSPredicate) -> Bool {
        return self.filterUsingPredicate(predicateClosure(Entity.self)).any()
    }
    
    public func none(@noescape predicateClosure: (Entity.Type) -> NSPredicate) -> Bool {
        return self.filterUsingPredicate(predicateClosure(Entity.self)).none()
    }
    
}

extension GenericQueryable {
    
    public func first(@noescape predicateClosure: (Entity.Type) -> NSPredicate) -> Entity? {
        return self.filterUsingPredicate(predicateClosure(Entity.self)).first()
    }
    
}

// MARK: - entity

extension GenericQueryable {
    
    public func first() -> Entity? {
        return self.take(1).toArray().first
    }
    
}
