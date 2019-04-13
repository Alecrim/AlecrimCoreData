//
//  Predicate.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 11/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// MARK: -

public class Predicate<Entity: ManagedObject> {

    public let rawValue: NSPredicate

    public var predicateFormat: String {
        return self.rawValue.predicateFormat
    }

    public convenience init(format predicateFormat: String, argumentArray arguments: [Any]?) {
        self.init(rawValue: NSPredicate(format: predicateFormat, argumentArray: arguments))
    }


    public convenience init(format predicateFormat: String, arguments argList: CVaListPointer) {
        self.init(rawValue: NSPredicate(format: predicateFormat, arguments: argList))
    }

    public convenience init(value: Bool) {
        self.init(rawValue: NSPredicate(value: value))
    }

    public init(rawValue: NSPredicate) {
        self.rawValue = rawValue
    }

}

// MARK: -

public final class ComparisonPredicate<Entity: ManagedObject>: Predicate<Entity> {

    public typealias Modifier = NSComparisonPredicate.Modifier
    public typealias Operator = NSComparisonPredicate.Operator
    public typealias Options = NSComparisonPredicate.Options

    public let leftExpression: NSExpression
    public let rightExpression: NSExpression

    public let modifier: Modifier
    public let operatorType: Operator

    public let options: Options

    public init(leftExpression left: Expression, rightExpression right: Expression, modifier: Modifier, type operatorType: Operator, options: Options = []) {
        //
        self.leftExpression = left
        self.rightExpression = right
        self.modifier = modifier
        self.operatorType = operatorType
        self.options = options

        //
        let predicate = NSComparisonPredicate(
            leftExpression: self.leftExpression,
            rightExpression: self.rightExpression,
            modifier: self.modifier,
            type: self.operatorType,
            options: self.options
        )

        super.init(rawValue: predicate)
    }

}

// MARK: -

public final class CompoundPredicate<Entity: ManagedObject>: Predicate<Entity> {

    public typealias LogicalType = NSCompoundPredicate.LogicalType

    public let type: LogicalType
    public let subpredicates: [Predicate<Entity>]

    public init(type: LogicalType, subpredicates: [Predicate<Entity>]) {
        //
        self.type = type
        self.subpredicates = subpredicates

        //
        let predicate = NSCompoundPredicate(type: self.type, subpredicates: self.subpredicates.map { $0.rawValue })

        super.init(rawValue: predicate)
    }

    public convenience init(andPredicateWithSubpredicates subpredicates: [Predicate<Entity>]) {
        self.init(type: .and, subpredicates: subpredicates)
    }

    public convenience init(orPredicateWithSubpredicates subpredicates: [Predicate<Entity>]) {
        self.init(type: .or, subpredicates: subpredicates)
    }

    public convenience init(notPredicateWithSubpredicate predicate: Predicate<Entity>) {
        self.init(type: .not, subpredicates: [predicate])
    }

}

// MARK: -

public func &&<Entity>(left: Predicate<Entity>, right: Predicate<Entity>) -> Predicate<Entity> {
    return CompoundPredicate<Entity>(type: .and, subpredicates: [left, right])
}

public func ||<Entity>(left: Predicate<Entity>, right: Predicate<Entity>) -> Predicate<Entity> {
    return CompoundPredicate<Entity>(type: .or, subpredicates: [left, right])
}

prefix public func !<Entity>(left: Predicate<Entity>) -> Predicate<Entity> {
    return CompoundPredicate<Entity>(type: .not, subpredicates: [left])
}

