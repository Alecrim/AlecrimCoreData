//
//  KeyPath.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 11/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

// .equalTo

public func ==<Entity: ManagedObject, Value: Equatable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .equalTo,
        options: right.comparisonOptions
    )
}

public func ==<Entity: ManagedObject, Value: Equatable>(left: KeyPath<Entity, Optional<Value>>, right: Optional<Value>) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .equalTo,
        options: right?.comparisonOptions ?? []
    )
}

// .notEqualTo

public func !=<Entity: ManagedObject, Value: Equatable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .notEqualTo,
        options: right.comparisonOptions
    )
}

public func !=<Entity: ManagedObject, Value: Equatable>(left: KeyPath<Entity, Optional<Value>>, right: Optional<Value>) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .notEqualTo,
        options: right?.comparisonOptions ?? []
    )
}

// .lessThan

public func <<Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .lessThan,
        options: right.comparisonOptions
    )
}

public func <<Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Optional<Value>>, right: Optional<Value>) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .lessThan,
        options: right?.comparisonOptions ?? []
    )
}

// .lessThanOrEqualTo

public func <=<Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .lessThanOrEqualTo,
        options: right.comparisonOptions
    )
}

public func <=<Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Optional<Value>>, right: Optional<Value>) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .lessThanOrEqualTo,
        options: right?.comparisonOptions ?? []
    )
}

// .greaterThan

public func ><Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .greaterThan,
        options: right.comparisonOptions
    )
}

public func ><Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Optional<Value>>, right: Optional<Value>) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .greaterThan,
        options: right?.comparisonOptions ?? []
    )
}

// .greaterThanOrEqualTo

public func >=<Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .greaterThanOrEqualTo,
        options: right.comparisonOptions
    )
}

public func >=<Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Optional<Value>>, right: Optional<Value>) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .greaterThanOrEqualTo,
        options: right?.comparisonOptions ?? []
    )
}

// .matches

// .like

// .beginsWith

// .endsWith

// .`in`

// .contains

// .between

// MARK: -

//extension KeyPath {
//
//    internal var pathString: String {
//        return self._kvcKeyPathString!
//    }
//
//}

// MARK: -

extension Equatable {
    
    fileprivate var comparisonOptions: ComparisonPredicate<ManagedObject>.Options {
        if self is String || self is NSString {
            return Config.defaultComparisonOptions
        }
        
        return []
    }
    
}

