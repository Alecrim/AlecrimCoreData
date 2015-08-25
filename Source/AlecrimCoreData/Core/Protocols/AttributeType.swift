//
//  AttributeType.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-06-17.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

//
//  Portions of this Software may utilize modified versions of the following
//  open source copyrighted material, the use of which is hereby acknowledged:
//
//  QueryKit [https://github.com/QueryKit/QueryKit]
//  Copyright (c) 2012-2014 Kyle Fuller. All rights reserved.
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

/// An attribute that has a name.
public protocol NamedAttributeType {
    
    // These properties have underscores as prefix to not conflict with entity property names.
    
    var ___name: String { get }
    var ___expression: NSExpression { get }
    
}

/// An attribute that has a name, an associated value type and that can not be compared to nil.
public protocol AttributeType: NamedAttributeType {
    
    /// The associated value type.
    typealias ValueType
    
}

/// An attribute that has a name, an associated value type and that can be compared to nil.
public protocol NullableAttributeType: AttributeType {
    
}

// MARK: - public protocol extensions - default implementations

extension AttributeType {
    
    public var ___expression: NSExpression {
        return NSExpression(forKeyPath: self.___name)
    }
    
}

// MARK: - internal protocol extensions

extension AttributeType {

    internal var ___comparisonPredicateOptions: NSComparisonPredicateOptions {
        if Self.ValueType.self is AlecrimCoreData.StringType.Type {
            return DataContextOptions.defaultComparisonPredicateOptions
        }
        else {
            return NSComparisonPredicateOptions()
        }
    }
    
}

// MARK: - public protocol extensions

extension AttributeType where Self.ValueType: Equatable {
    
    public func isEqualTo(value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .EqualToPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public func isEqualTo<T: AttributeType where T.ValueType == Self.ValueType>(otherAttribute: T) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .DirectPredicateModifier,
            type: .EqualToPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }

    public func isNotEqualTo(value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .NotEqualToPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public func isNotEqualTo<T: AttributeType where T.ValueType == Self.ValueType>(otherAttribute: T) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .DirectPredicateModifier,
            type: .NotEqualToPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

extension NullableAttributeType where Self.ValueType: Equatable {
    
    public func isEqualTo(value: ValueType?) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .EqualToPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public func isNotEqualTo(value: ValueType?) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .NotEqualToPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

extension AttributeType where Self.ValueType: Comparable {

    public func isGreaterThan(value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .GreaterThanPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public func isGreaterThan<T: AttributeType where T.ValueType == Self.ValueType>(otherAttribute: T) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .DirectPredicateModifier,
            type: .GreaterThanPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }

    public func isGreaterThanOrEqual(value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .GreaterThanOrEqualToPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public func isGreaterThanOrEqual<T: AttributeType where T.ValueType == Self.ValueType>(otherAttribute: T) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .DirectPredicateModifier,
            type: .GreaterThanOrEqualToPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }

    public func isLessThan(value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .LessThanPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public func isLessThan<T: AttributeType where T.ValueType == Self.ValueType>(otherAttribute: T) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .DirectPredicateModifier,
            type: .LessThanPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }

    public func isLessThanOrEqual(value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .LessThanOrEqualToPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public func isLessThanOrEqual<T: AttributeType where T.ValueType == Self.ValueType>(otherAttribute: T) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .DirectPredicateModifier,
            type: .LessThanOrEqualToPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

extension AttributeType where Self.ValueType: AlecrimCoreData.StringType {
    
    public func isLike(value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .LikePredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }

    public func isIn(value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .InPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }

}

extension AttributeType {

    public func isIn(values: [Self.ValueType]) -> NSComparisonPredicate {
        let rightExpressionConstanteValue = values.map { toAnyObject($0) }
        let rightExpression = NSExpression(forConstantValue: rightExpressionConstanteValue)
        
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: rightExpression,
            modifier: .DirectPredicateModifier,
            type: .InPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

extension AttributeType where Self.ValueType: ForwardIndexType {
    
    public func isBetween(range: Range<ValueType>) -> NSComparisonPredicate {
        let rightExpressionConstanteValue = [toAnyObject(range.startIndex), toAnyObject(range.endIndex)] as NSArray
        let rightExpression = NSExpression(forConstantValue: rightExpressionConstanteValue)
        
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: rightExpression,
            modifier: .DirectPredicateModifier,
            type: .BetweenPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

extension AttributeType where Self.ValueType: BooleanType {
    
    public func not() -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: NSExpression(forConstantValue: NSNumber(bool: false)),
            modifier: .DirectPredicateModifier,
            type: .EqualToPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

extension AttributeType where Self.ValueType: AlecrimCoreData.StringType {

    public func contains(value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .ContainsPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public func contains<T: AttributeType where T.ValueType == Self.ValueType>(otherAttribute: T) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .DirectPredicateModifier,
            type: .ContainsPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public func beginsWith(value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .BeginsWithPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }

    public func beginsWith<T: AttributeType where T.ValueType == Self.ValueType>(otherAttribute: T) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .DirectPredicateModifier,
            type: .BeginsWithPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }

    public func endsWith(value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .EndsWithPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public func endsWith<T: AttributeType where T.ValueType == Self.ValueType>(otherAttribute: T) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .DirectPredicateModifier,
            type: .EndsWithPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

extension AttributeType where Self.ValueType: AlecrimCoreData.StringType {
    
    public func matches(regularExpressionString: String) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: NSExpression(forConstantValue: regularExpressionString),
            modifier: .DirectPredicateModifier,
            type: .MatchesPredicateOperatorType,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

// MARK: - CollectionType

extension AttributeType where Self.ValueType: CollectionType {
    
    public func any(@noescape predicateClosure: (Self.ValueType.Generator.Element.Type) -> NSComparisonPredicate) -> NSComparisonPredicate {
        let p = predicateClosure(Self.ValueType.Generator.Element.self)
        
        var leftExpression = p.leftExpression
        if leftExpression.expressionType == .KeyPathExpressionType {
            leftExpression = NSExpression(forKeyPath: "\(self.___name).\(leftExpression.keyPath)")
        }
        
        var rightExpression = p.rightExpression
        if rightExpression.expressionType == .KeyPathExpressionType {
            rightExpression = NSExpression(forKeyPath: "\(self.___name).\(rightExpression.keyPath)")
        }
        
        return NSComparisonPredicate(
            leftExpression: leftExpression,
            rightExpression: rightExpression,
            modifier: .AnyPredicateModifier,
            type: p.predicateOperatorType,
            options: p.options
        )
    }
    
    public func all(@noescape predicateClosure: (Self.ValueType.Generator.Element.Type) -> NSComparisonPredicate) -> NSComparisonPredicate {
        let p = predicateClosure(Self.ValueType.Generator.Element.self)
        
        var leftExpression = p.leftExpression
        if leftExpression.expressionType == .KeyPathExpressionType {
            leftExpression = NSExpression(forKeyPath: "\(self.___name).\(leftExpression.keyPath)")
        }
        
        var rightExpression = p.rightExpression
        if rightExpression.expressionType == .KeyPathExpressionType {
            rightExpression = NSExpression(forKeyPath: "\(self.___name).\(rightExpression.keyPath)")
        }
        
        return NSComparisonPredicate(
            leftExpression: leftExpression,
            rightExpression: rightExpression,
            modifier: .AllPredicateModifier,
            type: p.predicateOperatorType,
            options: p.options
        )
    }

    public func none(@noescape predicateClosure: (Self.ValueType.Generator.Element.Type) -> NSComparisonPredicate) -> NSPredicate {
        let p = predicateClosure(Self.ValueType.Generator.Element.self)
        
        var leftExpression = p.leftExpression
        if leftExpression.expressionType == .KeyPathExpressionType {
            leftExpression = NSExpression(forKeyPath: "\(self.___name).\(leftExpression.keyPath)")
        }
        
        var rightExpression = p.rightExpression
        if rightExpression.expressionType == .KeyPathExpressionType {
            rightExpression = NSExpression(forKeyPath: "\(self.___name).\(rightExpression.keyPath)")
        }
        
        let allPredicate = NSComparisonPredicate(
            leftExpression: leftExpression,
            rightExpression: rightExpression,
            modifier: .AllPredicateModifier,
            type: p.predicateOperatorType,
            options: p.options
        )
        
        // this is really ugly! (where is the NSComparisonPredicateModifier.NonePredicateModifier?)
        // TODO: find a better way to do this
        let format = "NONE" + (allPredicate.description as NSString).substringFromIndex(3)
        
        //
        return NSPredicate(format: format)
    }

}

// MARK: - convenience operators

public func ==<A: AttributeType, V where A.ValueType: Equatable, A.ValueType == V>(left: A, right: V) -> NSComparisonPredicate {
    return left.isEqualTo(right)
}

public func ==<L: AttributeType, R: AttributeType where L.ValueType: Equatable, L.ValueType == R.ValueType>(left: L, right: R) -> NSComparisonPredicate {
    return left.isEqualTo(right)
}

public func ==<A: NullableAttributeType, V where A.ValueType: Equatable, A.ValueType == V>(left: A, right: V?) -> NSComparisonPredicate {
    return left.isEqualTo(right)
}

public func !=<A: AttributeType, V where A.ValueType: Equatable, A.ValueType == V>(left: A, right: V) -> NSComparisonPredicate {
    return left.isNotEqualTo(right)
}

public func !=<L: AttributeType, R: AttributeType where L.ValueType: Equatable, L.ValueType == R.ValueType>(left: L, right: R) -> NSComparisonPredicate {
    return left.isNotEqualTo(right)
}

public func !=<A: NullableAttributeType, V where A.ValueType: Equatable, A.ValueType == V>(left: A, right: V?) -> NSComparisonPredicate {
    return left.isNotEqualTo(right)
}

public func ><A: AttributeType, V where A.ValueType: Comparable, A.ValueType == V>(left: A, right: V) -> NSComparisonPredicate {
    return left.isGreaterThan(right)
}

public func ><L: AttributeType, R: AttributeType where L.ValueType: Comparable, L.ValueType == R.ValueType>(left: L, right: R) -> NSComparisonPredicate {
    return left.isGreaterThan(right)
}

public func >=<A: AttributeType, V where A.ValueType: Comparable, A.ValueType == V>(left: A, right: V) -> NSComparisonPredicate {
    return left.isGreaterThanOrEqual(right)
}

public func >=<L: AttributeType, R: AttributeType where L.ValueType: Comparable, L.ValueType == R.ValueType>(left: L, right: R) -> NSComparisonPredicate {
    return left.isGreaterThanOrEqual(right)
}

public func <<A: AttributeType, V where A.ValueType: Comparable, A.ValueType == V>(left: A, right: V) -> NSComparisonPredicate {
    return left.isLessThan(right)
}

public func <<L: AttributeType, R: AttributeType where L.ValueType: Comparable, L.ValueType == R.ValueType>(left: L, right: R) -> NSComparisonPredicate {
    return left.isLessThan(right)
}

public func <=<A: AttributeType, V where A.ValueType: Comparable, A.ValueType == V>(left: A, right: V) -> NSComparisonPredicate {
    return left.isLessThanOrEqual(right)
}

public func <=<L: AttributeType, R: AttributeType where L.ValueType: Comparable, L.ValueType == R.ValueType>(left: L, right: R) -> NSComparisonPredicate {
    return left.isLessThanOrEqual(right)
}

public func ~=<A: AttributeType, V where A.ValueType: AlecrimCoreData.StringType, A.ValueType == V>(left: A, right: V) -> NSComparisonPredicate {
    return left.isLike(right)
}

public func <<<A: AttributeType, V where A.ValueType: AlecrimCoreData.StringType, A.ValueType == V>(left: A, right: V) -> NSComparisonPredicate {
    return left.isIn(right)
}

public func <<<A: AttributeType, V where A.ValueType == V>(left: A, right: [V]) -> NSComparisonPredicate {
    return left.isIn(right)
}

public func <<<A: AttributeType, V: ForwardIndexType where A.ValueType == V>(left: A, right: Range<V>) -> NSComparisonPredicate {
    return left.isBetween(right)
}

prefix public func !<A: AttributeType where A.ValueType: BooleanType>(left: A) -> NSComparisonPredicate {
    return left.not()
}

// MARK: - helpers protocols

public protocol StringType {}
extension String: AlecrimCoreData.StringType {}
extension NSString: AlecrimCoreData.StringType {}

// MARK: - private functions

private func expressionForValue<T>(value: T) -> NSExpression {
    let object: AnyObject = toAnyObject(value)
    return NSExpression(forConstantValue: (object is NSNull ? nil : object))
}

private func toAnyObject<T>(value: T) -> AnyObject {
    //
    if let v = value as? AnyObject {
        return v
    }
    else if let v = value as? String {
        return v as NSString
    }
    else if let v = value as? Int {
        return NSNumber(integer: v)
    }
    else if let v = value as? Int64 {
        return NSNumber(longLong: v)
    }
    else if let v = value as? Int32 {
        return NSNumber(int: v)
    }
    else if let v = value as? Int16 {
        return NSNumber(short: v)
    }
    else if let v = value as? Double {
        return NSNumber(double: v)
    }
    else if let v = value as? Float {
        return NSNumber(float: v)
    }
    else if let v = value as? Bool {
        return NSNumber(bool: v)
    }
    else {
        // HAX: the value may be an optional, so we have to test the optional object type, one by one
        let mirror = _reflect(value)
        if mirror.disposition == .Optional {
            let dt = value.dynamicType
            
            // reference types
            if dt is NSObject?.Type {
                if let v = unsafeBitCast(value, Optional<NSObject>.self) {
                    return v
                }
            }
            else if dt is NSString?.Type {
                if let v = unsafeBitCast(value, Optional<NSString>.self) {
                    return v
                }
            }
            else if dt is NSDate?.Type {
                if let v = unsafeBitCast(value, Optional<NSDate>.self) {
                    return v
                }
            }
            else if dt is NSDecimalNumber?.Type {
                if let v = unsafeBitCast(value, Optional<NSDecimalNumber>.self) {
                    return v
                }
            }
            else if dt is NSNumber?.Type {
                if let v = unsafeBitCast(value, Optional<NSNumber>.self) {
                    return v
                }
            }
            else if dt is NSData?.Type {
                if let v = unsafeBitCast(value, Optional<NSData>.self) {
                    return v
                }
            }
            
            // value types
            if dt is String?.Type {
                if let v = unsafeBitCast(value, Optional<String>.self) {
                    return v as NSString
                }
            }
            else if dt is Int?.Type {
                if let v = unsafeBitCast(value, Optional<Int>.self) {
                    return NSNumber(integer: v)
                }
            }
            else if dt is Int64?.Type {
                if let v = unsafeBitCast(value, Optional<Int64>.self) {
                    return NSNumber(longLong: v)
                }
            }
            else if dt is Int32?.Type {
                if let v = unsafeBitCast(value, Optional<Int32>.self) {
                    return NSNumber(int: v)
                }
            }
            else if dt is Int16?.Type {
                if let v = unsafeBitCast(value, Optional<Int16>.self) {
                    return NSNumber(short: v)
                }
            }
            else if dt is Double?.Type {
                if let v = unsafeBitCast(value, Optional<Double>.self) {
                    return NSNumber(double: v)
                }
            }
            else if dt is Float?.Type {
                if let v = unsafeBitCast(value, Optional<Float>.self) {
                    return NSNumber(float: v)
                }
            }
            else if dt is Bool?.Type {
                if let v = unsafeBitCast(value, Optional<Bool>.self) {
                    return NSNumber(bool: v)
                }
            }
        }
    }
    
    // the value is nil or not compatible with Core Data
    return NSNull()
}

