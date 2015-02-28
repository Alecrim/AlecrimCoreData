//
//  Attribute.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-02-25.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

//
//  Contains modified versions of QueryKit (https://github.com/QueryKit/QueryKit)
//  Attribute.swift, Expression.swift and Predicate.swift source codes
//
//  Copyright (c) 2012-2014, Kyle Fuller
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//     list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation

public final class Attribute<T> {
    
    public let name: String
    
    public init(_ name: String) {
        self.name = name
    }
    
    private lazy var expression: NSExpression = { return NSExpression(forKeyPath: self.name) }()
    
    private func expressionForValue(value: T) -> NSExpression {
        // TODO: Find a cleaner implementation
        if let value = value as? NSObject {
            return NSExpression(forConstantValue: value as NSObject)
        }
        
        if sizeof(value.dynamicType) == 8 {
            let value = unsafeBitCast(value, Optional<NSObject>.self)
            if let value = value {
                return NSExpression(forConstantValue: value)
            }
        }
        
        let value = unsafeBitCast(value, Optional<String>.self)
        if let value = value {
            return NSExpression(forConstantValue: value)
        }
        
        return NSExpression(forConstantValue: NSNull())
    }
    
}

// MARK: - Equatable protocol

extension Attribute: Equatable {
    // Swift language development team:
    // I still think the operator func implementation should be in here and not out there.
}

public func ==<T>(left: Attribute<T>, right: Attribute<T>) -> Bool {
    return left.name == right.name
}

// MARK: - Attribute operators

public func ==<T>(left: Attribute<T>, right: T) -> NSPredicate {
    return left.expression == left.expressionForValue(right)
}

public func ==<T>(left: Attribute<T>, right: Attribute<T>) -> NSPredicate {
    return left.expression == right.expression
}

public func !=<T>(left: Attribute<T>, right: T) -> NSPredicate {
    return left.expression != left.expressionForValue(right)
}

public func !=<T>(left: Attribute<T>, right: Attribute<T>) -> NSPredicate {
    return left.expression != right.expression
}

public func ><T>(left: Attribute<T>, right: T) -> NSPredicate {
    return left.expression > left.expressionForValue(right)
}

public func ><T>(left: Attribute<T>, right: Attribute<T>) -> NSPredicate {
    return left.expression > right.expression
}

public func >=<T>(left: Attribute<T>, right: T) -> NSPredicate {
    return left.expression >= left.expressionForValue(right)
}

public func >=<T>(left: Attribute<T>, right: Attribute<T>) -> NSPredicate {
    return left.expression >= right.expression
}

public func <<T>(left: Attribute<T>, right: T) -> NSPredicate {
    return left.expression < left.expressionForValue(right)
}

public func <<T>(left: Attribute<T>, right: Attribute<T>) -> NSPredicate {
    return left.expression < right.expression
}

public func <=<T>(left: Attribute<T>, right: T) -> NSPredicate {
    return left.expression <= left.expressionForValue(right)
}

public func <=<T>(left: Attribute<T>, right: Attribute<T>) -> NSPredicate {
    return left.expression <= right.expression
}

public func ~=<T>(left: Attribute<T>, right: T) -> NSPredicate {
    return left.expression ~= left.expressionForValue(right)
}

public func <<<T>(left: Attribute<T>, right: [T]) -> NSPredicate {
    return left.expression << NSExpression(forConstantValue: right as! AnyObject)
}

public func <<<T>(left: Attribute<T>, right: Range<T>) -> NSPredicate {
    let rightExpression = NSExpression(forConstantValue: [right.startIndex, right.endIndex] as! AnyObject)
    
    return NSComparisonPredicate(leftExpression: left.expression, rightExpression: rightExpression, modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.BetweenPredicateOperatorType, options: NSComparisonPredicateOptions(0))
}

prefix public func !(left: Attribute<Bool>) -> NSPredicate {
    return left == false
}

// MARK: - NSPredicate - public extensions

public func &&(left: NSPredicate, right: NSPredicate) -> NSPredicate {
    return NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [left, right])
}

public func ||(left: NSPredicate, right: NSPredicate) -> NSPredicate {
    return NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType, subpredicates: [left, right])
}

prefix public func !(left: NSPredicate) -> NSPredicate {
    return NSCompoundPredicate(type: NSCompoundPredicateType.NotPredicateType, subpredicates: [left])
}

// MARK: - NSExpression - private extensions

private func ==(left: NSExpression, right: NSExpression) -> NSPredicate {
    return NSComparisonPredicate(leftExpression: left, rightExpression: right, modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.EqualToPredicateOperatorType, options: NSComparisonPredicateOptions(0))
}

private func !=(left: NSExpression, right: NSExpression) -> NSPredicate {
    return NSComparisonPredicate(leftExpression: left, rightExpression: right, modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.NotEqualToPredicateOperatorType, options: NSComparisonPredicateOptions(0))
}

private func >(left: NSExpression, right: NSExpression) -> NSPredicate {
    return NSComparisonPredicate(leftExpression: left, rightExpression: right, modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.GreaterThanPredicateOperatorType, options: NSComparisonPredicateOptions(0))
}

private func >=(left: NSExpression, right: NSExpression) -> NSPredicate {
    return NSComparisonPredicate(leftExpression: left, rightExpression: right, modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.GreaterThanOrEqualToPredicateOperatorType, options: NSComparisonPredicateOptions(0))
}

private func <(left: NSExpression, right: NSExpression) -> NSPredicate {
    return NSComparisonPredicate(leftExpression: left, rightExpression: right, modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.LessThanPredicateOperatorType, options: NSComparisonPredicateOptions(0))
}

private func <=(left: NSExpression, right: NSExpression) -> NSPredicate {
    return NSComparisonPredicate(leftExpression: left, rightExpression: right, modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.LessThanOrEqualToPredicateOperatorType, options: NSComparisonPredicateOptions(0))
}

private func ~=(left: NSExpression, right: NSExpression) -> NSPredicate {
    return NSComparisonPredicate(leftExpression: left, rightExpression: right, modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.LikePredicateOperatorType, options: NSComparisonPredicateOptions(0))
}

private func <<(left: NSExpression, right: NSExpression) -> NSPredicate {
    return NSComparisonPredicate(leftExpression: left, rightExpression: right, modifier: NSComparisonPredicateModifier.DirectPredicateModifier, type: NSPredicateOperatorType.InPredicateOperatorType, options: NSComparisonPredicateOptions(0))
}
