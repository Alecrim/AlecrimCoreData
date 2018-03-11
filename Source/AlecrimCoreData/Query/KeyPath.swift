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
        options: right.comparisonPredicateOptions
    )
}

public func ==<Entity: ManagedObject, Value: Equatable>(left: KeyPath<Entity, Optional<Value>>, right: Optional<Value>) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .equalTo,
        options: right?.comparisonPredicateOptions ?? []
    )
}

// .notEqualTo

public func !=<Entity: ManagedObject, Value: Equatable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .notEqualTo,
        options: right.comparisonPredicateOptions
    )
}

public func !=<Entity: ManagedObject, Value: Equatable>(left: KeyPath<Entity, Optional<Value>>, right: Optional<Value>) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .notEqualTo,
        options: right?.comparisonPredicateOptions ?? []
    )
}

// .lessThan

public func <<Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .lessThan,
        options: right.comparisonPredicateOptions
    )
}

public func <<Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Optional<Value>>, right: Optional<Value>) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .lessThan,
        options: right?.comparisonPredicateOptions ?? []
    )
}

// .lessThanOrEqualTo

public func <=<Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .lessThanOrEqualTo,
        options: right.comparisonPredicateOptions
    )
}

public func <=<Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Optional<Value>>, right: Optional<Value>) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .lessThanOrEqualTo,
        options: right?.comparisonPredicateOptions ?? []
    )
}

// .greaterThan

public func ><Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .greaterThan,
        options: right.comparisonPredicateOptions
    )
}

public func ><Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Optional<Value>>, right: Optional<Value>) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .greaterThan,
        options: right?.comparisonPredicateOptions ?? []
    )
}

// .greaterThanOrEqualTo

public func >=<Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Value>, right: Value) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .greaterThanOrEqualTo,
        options: right.comparisonPredicateOptions
    )
}

public func >=<Entity: ManagedObject, Value: Comparable>(left: KeyPath<Entity, Optional<Value>>, right: Optional<Value>) -> ComparisonPredicate<Entity> {
    return ComparisonPredicate<Entity>(
        leftExpression: Expression(forKeyPath: left),
        rightExpression: Expression(forConstantValue: right),
        modifier: .direct,
        type: .greaterThanOrEqualTo,
        options: right?.comparisonPredicateOptions ?? []
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

extension KeyPath {

    internal var pathString: String {
        return self._kvcKeyPathString!
    }

}

// MARK: -

extension Equatable {
    
    fileprivate var comparisonPredicateOptions: ComparisonPredicate<ManagedObject>.Options {
        if self is String || self is NSString {
            return Config.defaultComparisonPredicateOptions
        }
        
        return []
    }
    
}

