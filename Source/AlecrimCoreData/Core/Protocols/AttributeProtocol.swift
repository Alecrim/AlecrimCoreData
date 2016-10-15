//
//  AttributeProtocol.swift
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
public protocol NamedAttributeProtocol {
    
    // These properties have underscores as prefix to not conflict with entity property names.
    
    var ___name: String { get }
    var ___expression: NSExpression { get }
    
}

/// An attribute that has a name, an associated value type and that can not be compared to nil.
public protocol AttributeProtocol: NamedAttributeProtocol {
    
    /// The associated value type.
    associatedtype ValueType
    
}

/// An attribute that has a name, an associated value type and that can be compared to nil.
public protocol NullableAttributeProtocol: AttributeProtocol {
    
}

// MARK: - public protocol extensions - default implementations

extension AttributeProtocol {
    
    public final var ___expression: NSExpression {
        return NSExpression(forKeyPath: self.___name)
    }
    
}

// MARK: - internal protocol extensions

extension AttributeProtocol {

    internal final var ___comparisonPredicateOptions: NSComparisonPredicate.Options {
        if Self.ValueType.self is AlecrimCoreData.StringProtocol.Type {
            return PersistentContainerOptions.defaultComparisonPredicateOptions
        }
        else {
            return NSComparisonPredicate.Options()
        }
    }
    
}

// MARK: - public protocol extensions

extension AttributeProtocol where Self.ValueType: Equatable {
    
    public final func isEqualTo(_ value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .direct,
            type: .equalTo,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public final func isEqualTo<T: AttributeProtocol>(_ otherAttribute: T) -> NSComparisonPredicate where T.ValueType == Self.ValueType {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .direct,
            type: .equalTo,
            options: self.___comparisonPredicateOptions
        )
    }

    public final func isNotEqualTo(_ value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .direct,
            type: .notEqualTo,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public final func isNotEqualTo<T: AttributeProtocol>(_ otherAttribute: T) -> NSComparisonPredicate where T.ValueType == Self.ValueType {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .direct,
            type: .notEqualTo,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

extension NullableAttributeProtocol where Self.ValueType: Equatable {
    
    public final func isEqualTo(_ value: ValueType?) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .direct,
            type: .equalTo,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public final func isNotEqualTo(_ value: ValueType?) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .direct,
            type: .notEqualTo,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

extension AttributeProtocol where Self.ValueType: Comparable {

    public final func isGreaterThan(_ value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .direct,
            type: .greaterThan,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public final func isGreaterThan<T: AttributeProtocol>(_ otherAttribute: T) -> NSComparisonPredicate where T.ValueType == Self.ValueType {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .direct,
            type: .greaterThan,
            options: self.___comparisonPredicateOptions
        )
    }

    public final func isGreaterThanOrEqualTo(_ value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .direct,
            type: .greaterThanOrEqualTo,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public final func isGreaterThanOrEqualTo<T: AttributeProtocol>(_ otherAttribute: T) -> NSComparisonPredicate where T.ValueType == Self.ValueType {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .direct,
            type: .greaterThanOrEqualTo,
            options: self.___comparisonPredicateOptions
        )
    }

    public final func isLessThan(_ value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .direct,
            type: .lessThan,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public final func isLessThan<T: AttributeProtocol>(_ otherAttribute: T) -> NSComparisonPredicate where T.ValueType == Self.ValueType {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .direct,
            type: .lessThan,
            options: self.___comparisonPredicateOptions
        )
    }

    public final func isLessThanOrEqualTo(_ value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .direct,
            type: .lessThanOrEqualTo,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public final func isLessThanOrEqualTo<T: AttributeProtocol>(_ otherAttribute: T) -> NSComparisonPredicate where T.ValueType == Self.ValueType {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .direct,
            type: .lessThanOrEqualTo,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

extension AttributeProtocol where Self.ValueType: AlecrimCoreData.StringProtocol {
    
    public final func isLike(_ value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .direct,
            type: .like,
            options: self.___comparisonPredicateOptions
        )
    }

    public final func isIn(_ value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .direct,
            type: .in,
            options: self.___comparisonPredicateOptions
        )
    }

}

extension AttributeProtocol {

    public final func isIn(_ values: [Self.ValueType]) -> NSComparisonPredicate {
        let rightExpressionConstanteValue = values.map { toNSObject($0) }
        let rightExpression = NSExpression(forConstantValue: rightExpressionConstanteValue)
        
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: rightExpression,
            modifier: .direct,
            type: .in,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

extension AttributeProtocol where Self.ValueType: Comparable {
    
    public final func isBetween(_ range: Range<ValueType>) -> NSComparisonPredicate {
        let rightExpressionConstanteValue = [toNSObject(range.lowerBound), toNSObject(range.upperBound)] as NSArray
        let rightExpression = NSExpression(forConstantValue: rightExpressionConstanteValue)
        
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: rightExpression,
            modifier: .direct,
            type: .between,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

extension AttributeProtocol where Self.ValueType: ExpressibleByBooleanLiteral {
    
    public final func not() -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: NSExpression(forConstantValue: NSNumber(value: false)),
            modifier: .direct,
            type: .equalTo,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

extension AttributeProtocol where Self.ValueType: AlecrimCoreData.StringProtocol {

    public final func contains(_ value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .direct,
            type: .contains,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public final func contains<T: AttributeProtocol>(_ otherAttribute: T) -> NSComparisonPredicate where T.ValueType == Self.ValueType {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .direct,
            type: .contains,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public final func beginsWith(_ value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .direct,
            type: .beginsWith,
            options: self.___comparisonPredicateOptions
        )
    }

    public final func beginsWith<T: AttributeProtocol>(_ otherAttribute: T) -> NSComparisonPredicate where T.ValueType == Self.ValueType {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .direct,
            type: .beginsWith,
            options: self.___comparisonPredicateOptions
        )
    }

    public final func endsWith(_ value: Self.ValueType) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: expressionForValue(value),
            modifier: .direct,
            type: .endsWith,
            options: self.___comparisonPredicateOptions
        )
    }
    
    public final func endsWith<T: AttributeProtocol>(_ otherAttribute: T) -> NSComparisonPredicate where T.ValueType == Self.ValueType {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: otherAttribute.___expression,
            modifier: .direct,
            type: .endsWith,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

extension AttributeProtocol where Self.ValueType: AlecrimCoreData.StringProtocol {
    
    public final func matches(_ regularExpressionString: String) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.___expression,
            rightExpression: NSExpression(forConstantValue: regularExpressionString),
            modifier: .direct,
            type: .matches,
            options: self.___comparisonPredicateOptions
        )
    }
    
}

// MARK: - CollectionType

extension AttributeProtocol where Self.ValueType: Collection {
    
    public final func any(_ predicateClosure: (Self.ValueType.Iterator.Element.Type) -> NSComparisonPredicate) -> NSComparisonPredicate {
        let p = predicateClosure(Self.ValueType.Iterator.Element.self)
        
        var leftExpression = p.leftExpression
        if leftExpression.expressionType == .keyPath {
            leftExpression = NSExpression(forKeyPath: "\(self.___name).\(leftExpression.keyPath)")
        }
        
        var rightExpression = p.rightExpression
        if rightExpression.expressionType == .keyPath {
            rightExpression = NSExpression(forKeyPath: "\(self.___name).\(rightExpression.keyPath)")
        }
        
        return NSComparisonPredicate(
            leftExpression: leftExpression,
            rightExpression: rightExpression,
            modifier: .any,
            type: p.predicateOperatorType,
            options: p.options
        )
    }
    
    public final func all(_ predicateClosure: (Self.ValueType.Iterator.Element.Type) -> NSComparisonPredicate) -> NSComparisonPredicate {
        let p = predicateClosure(Self.ValueType.Iterator.Element.self)
        
        var leftExpression = p.leftExpression
        if leftExpression.expressionType == .keyPath {
            leftExpression = NSExpression(forKeyPath: "\(self.___name).\(leftExpression.keyPath)")
        }
        
        var rightExpression = p.rightExpression
        if rightExpression.expressionType == .keyPath {
            rightExpression = NSExpression(forKeyPath: "\(self.___name).\(rightExpression.keyPath)")
        }
        
        return NSComparisonPredicate(
            leftExpression: leftExpression,
            rightExpression: rightExpression,
            modifier: .all,
            type: p.predicateOperatorType,
            options: p.options
        )
    }

    public final func none(_ predicateClosure: (Self.ValueType.Iterator.Element.Type) -> NSComparisonPredicate) -> NSPredicate {
        let p = predicateClosure(Self.ValueType.Iterator.Element.self)
        
        var leftExpression = p.leftExpression
        if leftExpression.expressionType == .keyPath {
            leftExpression = NSExpression(forKeyPath: "\(self.___name).\(leftExpression.keyPath)")
        }
        
        var rightExpression = p.rightExpression
        if rightExpression.expressionType == .keyPath {
            rightExpression = NSExpression(forKeyPath: "\(self.___name).\(rightExpression.keyPath)")
        }
        
        let allPredicate = NSComparisonPredicate(
            leftExpression: leftExpression,
            rightExpression: rightExpression,
            modifier: .all,
            type: p.predicateOperatorType,
            options: p.options
        )
        
        // this is really ugly! (where is the NSComparisonPredicateModifier.NonePredicateModifier?)
        // TODO: find a better way to do this
        let format = "NONE" + (allPredicate.description as NSString).substring(from: 3)
        
        //
        return NSPredicate(format: format)
    }

}

// MARK: - convenience operators

public func == <A: AttributeProtocol, V>(left: A, right: V) -> NSComparisonPredicate where A.ValueType: Equatable, A.ValueType == V {
    return left.isEqualTo(right)
}

public func == <L: AttributeProtocol, R: AttributeProtocol>(left: L, right: R) -> NSComparisonPredicate where L.ValueType: Equatable, L.ValueType == R.ValueType {
    return left.isEqualTo(right)
}

public func == <A: NullableAttributeProtocol, V>(left: A, right: V?) -> NSComparisonPredicate where A.ValueType: Equatable, A.ValueType == V {
    return left.isEqualTo(right)
}

public func != <A: AttributeProtocol, V>(left: A, right: V) -> NSComparisonPredicate where A.ValueType: Equatable, A.ValueType == V {
    return left.isNotEqualTo(right)
}

public func != <L: AttributeProtocol, R: AttributeProtocol>(left: L, right: R) -> NSComparisonPredicate where L.ValueType: Equatable, L.ValueType == R.ValueType {
    return left.isNotEqualTo(right)
}

public func != <A: NullableAttributeProtocol, V>(left: A, right: V?) -> NSComparisonPredicate where A.ValueType: Equatable, A.ValueType == V {
    return left.isNotEqualTo(right)
}

public func > <A: AttributeProtocol, V>(left: A, right: V) -> NSComparisonPredicate where A.ValueType: Comparable, A.ValueType == V {
    return left.isGreaterThan(right)
}

public func > <L: AttributeProtocol, R: AttributeProtocol>(left: L, right: R) -> NSComparisonPredicate where L.ValueType: Comparable, L.ValueType == R.ValueType {
    return left.isGreaterThan(right)
}

public func >= <A: AttributeProtocol, V>(left: A, right: V) -> NSComparisonPredicate where A.ValueType: Comparable, A.ValueType == V {
    return left.isGreaterThanOrEqualTo(right)
}

public func >= <L: AttributeProtocol, R: AttributeProtocol>(left: L, right: R) -> NSComparisonPredicate where L.ValueType: Comparable, L.ValueType == R.ValueType {
    return left.isGreaterThanOrEqualTo(right)
}

public func < <A: AttributeProtocol, V>(left: A, right: V) -> NSComparisonPredicate where A.ValueType: Comparable, A.ValueType == V {
    return left.isLessThan(right)
}

public func < <L: AttributeProtocol, R: AttributeProtocol>(left: L, right: R) -> NSComparisonPredicate where L.ValueType: Comparable, L.ValueType == R.ValueType {
    return left.isLessThan(right)
}

public func <= <A: AttributeProtocol, V>(left: A, right: V) -> NSComparisonPredicate where A.ValueType: Comparable, A.ValueType == V {
    return left.isLessThanOrEqualTo(right)
}

public func <= <L: AttributeProtocol, R: AttributeProtocol>(left: L, right: R) -> NSComparisonPredicate where L.ValueType: Comparable, L.ValueType == R.ValueType {
    return left.isLessThanOrEqualTo(right)
}

public func ~= <A: AttributeProtocol, V>(left: A, right: V) -> NSComparisonPredicate where A.ValueType: AlecrimCoreData.StringProtocol, A.ValueType == V {
    return left.isLike(right)
}

public func << <A: AttributeProtocol, V>(left: A, right: V) -> NSComparisonPredicate where A.ValueType: AlecrimCoreData.StringProtocol, A.ValueType == V {
    return left.isIn(right)
}

public func << <A: AttributeProtocol, V>(left: A, right: [V]) -> NSComparisonPredicate where A.ValueType == V {
    return left.isIn(right)
}

public func << <A: AttributeProtocol, V: Comparable>(left: A, right: Range<V>) -> NSComparisonPredicate where A.ValueType == V {
    return left.isBetween(right)
}

prefix public func ! <A: AttributeProtocol>(left: A) -> NSComparisonPredicate where A.ValueType: ExpressibleByBooleanLiteral {
    return left.not()
}

// MARK: - helpers protocols

public protocol StringProtocol {}
extension String: AlecrimCoreData.StringProtocol {}
extension NSString: AlecrimCoreData.StringProtocol {}

// MARK: - private functions

private func expressionForValue<T>(_ value: T) -> NSExpression {
    let object: NSObject = toNSObject(value)
    return NSExpression(forConstantValue: (object is NSNull ? nil : object))
}

private func toNSObject<T>(_ value: T) -> NSObject {
    //
    if let v = value as? NSObject {
        return v
    }
    else if let v = value as? Int {
        return NSNumber(value: v)
    }
    else if let v = value as? Int64 {
        return NSNumber(value: v)
    }
    else if let v = value as? Int32 {
        return NSNumber(value: v)
    }
    else if let v = value as? Int16 {
        return NSNumber(value: v)
    }
    else if let v = value as? Double {
        return NSNumber(value: v)
    }
    else if let v = value as? Float {
        return NSNumber(value: v)
    }
    else if let v = value as? Bool {
        return NSNumber(value: v)
    }
    else if let v = value as? String {
        return v as NSString
    }
    else if let v = value as? Date {
        return v as NSDate
    }
    else if let v = value as? Data {
        return v as NSData
    }
    else {
        // HAX: the value may be an optional, so we have to test the optional object type, one by one
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            let dt = type(of: value)
            
            // reference types
            if dt is NSObject?.Type {
                if let v = unsafeBitCast(value, to: Optional<NSObject>.self) {
                    return v
                }
            }
            else if dt is NSDecimalNumber?.Type {
                if let v = unsafeBitCast(value, to: Optional<NSDecimalNumber>.self) {
                    return v
                }
            }
            else if dt is NSNumber?.Type {
                if let v = unsafeBitCast(value, to: Optional<NSNumber>.self) {
                    return v
                }
            }
            else if dt is NSString?.Type {
                if let v = unsafeBitCast(value, to: Optional<NSString>.self) {
                    return v
                }
            }
            else if dt is NSDate?.Type {
                if let v = unsafeBitCast(value, to: Optional<NSDate>.self) {
                    return v
                }
            }
            else if dt is NSData?.Type {
                if let v = unsafeBitCast(value, to: Optional<NSData>.self) {
                    return v
                }
            }
            
            // value types
            if dt is Int?.Type {
                if let v = unsafeBitCast(value, to: Optional<Int>.self) {
                    return NSNumber(value: v)
                }
            }
            else if dt is Int64?.Type {
                if let v = unsafeBitCast(value, to: Optional<Int64>.self) {
                    return NSNumber(value: v)
                }
            }
            else if dt is Int32?.Type {
                if let v = unsafeBitCast(value, to: Optional<Int32>.self) {
                    return NSNumber(value: v)
                }
            }
            else if dt is Int16?.Type {
                if let v = unsafeBitCast(value, to: Optional<Int16>.self) {
                    return NSNumber(value: v)
                }
            }
            else if dt is Double?.Type {
                if let v = unsafeBitCast(value, to: Optional<Double>.self) {
                    return NSNumber(value: v)
                }
            }
            else if dt is Float?.Type {
                if let v = unsafeBitCast(value, to: Optional<Float>.self) {
                    return NSNumber(value: v)
                }
            }
            else if dt is Bool?.Type {
                if let v = unsafeBitCast(value, to: Optional<Bool>.self) {
                    return NSNumber(value: v)
                }
            }
            else if dt is String?.Type {
                if let v = unsafeBitCast(value, to: Optional<String>.self) {
                    return v as NSString
                }
            }
            else if dt is Date?.Type {
                if let v = unsafeBitCast(value, to: Optional<Date>.self) {
                    return v as NSDate
                }
            }
            else if dt is Data?.Type {
                if let v = unsafeBitCast(value, to: Optional<Data>.self) {
                    return v as NSData
                }
            }
        }
    }
    
    // the value is nil or not compatible with Core Data
    return NSNull()
}

