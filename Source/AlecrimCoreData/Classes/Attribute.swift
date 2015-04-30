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

public class Attribute<T> {
    
    public let ___name: String
    
    public init(_ name: String) {
        self.___name = name
    }
    
    private var expression: NSExpression {
        return NSExpression(forKeyPath: self.___name)
    }
    
    private func expressionForValue(value: T) -> NSExpression {
        // TODO: Find a cleaner implementation
        let mirror = reflect(value)
        
        if mirror.disposition == .Optional {
            let dt = value.dynamicType

            // here we have to test the optional object type, one by one
            if dt is NSObject?.Type {
                let o = unsafeBitCast(value, Optional<NSObject>.self)
                if let v = o.0 {
                    return NSExpression(forConstantValue: v)
                }
            }
            else if dt is NSString?.Type {
                let o = unsafeBitCast(value, Optional<NSString>.self)
                if let v = o.0 {
                    return NSExpression(forConstantValue: v)
                }
            }
            else if dt is NSDate?.Type {
                let o = unsafeBitCast(value, Optional<NSDate>.self)
                if let v = o.0 {
                    return NSExpression(forConstantValue: v)
                }
            }
            else if dt is NSDecimalNumber?.Type {
                let o = unsafeBitCast(value, Optional<NSDecimalNumber>.self)
                if let v = o.0 {
                    return NSExpression(forConstantValue: v)
                }
            }
            else if dt is NSNumber?.Type {
                let o = unsafeBitCast(value, Optional<NSNumber>.self)
                if let v = o.0 {
                    return NSExpression(forConstantValue: v)
                }
            }
            else if dt is NSData?.Type {
                let o = unsafeBitCast(value, Optional<NSData>.self)
                if let v = o.0 {
                    return NSExpression(forConstantValue: v)
                }
            }

            //
            if dt is String?.Type {
                let o = unsafeBitCast(value, Optional<String>.self)
                if let v = o.0 {
                    return NSExpression(forConstantValue: v as NSString)
                }
            }
            else if dt is Int?.Type {
                let o = unsafeBitCast(value, Optional<Int>.self)
                if let v = o.0 {
                    return NSExpression(forConstantValue: NSNumber(integer: v))
                }
            }
            else if dt is Int64?.Type {
                let o = unsafeBitCast(value, Optional<Int64>.self)
                if let v = o.0 {
                    return NSExpression(forConstantValue: NSNumber(longLong: v))
                }
            }
            else if dt is Int32?.Type {
                let o = unsafeBitCast(value, Optional<Int32>.self)
                if let v = o.0 {
                    return NSExpression(forConstantValue: NSNumber(int: v))
                }
            }
            else if dt is Int16?.Type {
                let o = unsafeBitCast(value, Optional<Int16>.self)
                if let v = o.0 {
                    return NSExpression(forConstantValue: NSNumber(short: v))
                }
            }
            else if dt is Double?.Type {
                let o = unsafeBitCast(value, Optional<Double>.self)
                if let v = o.0 {
                    return NSExpression(forConstantValue: NSNumber(double: v))
                }
            }
            else if dt is Float?.Type {
                let o = unsafeBitCast(value, Optional<Float>.self)
                if let v = o.0 {
                    return NSExpression(forConstantValue: NSNumber(float: v))
                }
            }
            else if dt is Bool?.Type {
                let o = unsafeBitCast(value, Optional<Bool>.self)
                if let v = o.0 {
                    return NSExpression(forConstantValue: NSNumber(bool: v))
                }
            }
        }
        else {
            //
            if let v = value as? NSObject {
                return NSExpression(forConstantValue: v)
            }
            
            //
            if let v = value as? String {
                return NSExpression(forConstantValue: v as NSString)
            }
            else if let v = value as? Int {
                return NSExpression(forConstantValue: NSNumber(integer: v))
            }
            else if let v = value as? Int64 {
                return NSExpression(forConstantValue: NSNumber(longLong: v))
            }
            else if let v = value as? Int32 {
                return NSExpression(forConstantValue: NSNumber(int: v))
            }
            else if let v = value as? Int16 {
                return NSExpression(forConstantValue: NSNumber(short: v))
            }
            else if let v = value as? Double {
                return NSExpression(forConstantValue: NSNumber(double: v))
            }
            else if let v = value as? Float {
                return NSExpression(forConstantValue: NSNumber(float: v))
            }
            else if let v = value as? Bool {
                return NSExpression(forConstantValue: NSNumber(bool: v))
            }
        }
        
        return NSExpression(forConstantValue: NSNull())
    }
    
    private func comparisonPredicateOptions() -> NSComparisonPredicateOptions {
        if T.self is String.Type || T.self is String?.Type || T.self is NSString.Type || T.self is NSString?.Type {
            return ContextOptions.stringComparisonPredicateOptions
        }
        else {
            return NSComparisonPredicateOptions.allZeros
        }
    }
    
}

// MARK: - Equatable protocol

extension Attribute: Equatable {

}

public func ==<T>(left: Attribute<T>, right: Attribute<T>) -> Bool {
    return left.___name == right.___name
}

// MARK: - Hashable protocol

extension Attribute: Hashable {
    
    public var hashValue: Int { return self.___name.hashValue }
    
}

// MARK: - Attribute methods

extension Attribute {

    public func matches(regularExpressionString: String) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.expression,
            rightExpression: NSExpression(forConstantValue: regularExpressionString),
            modifier: .DirectPredicateModifier,
            type: .MatchesPredicateOperatorType,
            options: self.comparisonPredicateOptions()
        )
    }

    public func contains(value: T) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.expression,
            rightExpression: self.expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .ContainsPredicateOperatorType,
            options: self.comparisonPredicateOptions()
        )
    }
    
    public func contains(otherAttribute: Attribute<T>) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.expression,
            rightExpression: otherAttribute.expression,
            modifier: .DirectPredicateModifier,
            type: .ContainsPredicateOperatorType,
            options: self.comparisonPredicateOptions()
        )
    }

    public func beginsWith(value: T) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.expression,
            rightExpression: self.expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .BeginsWithPredicateOperatorType,
            options: self.comparisonPredicateOptions()
        )
    }

    public func beginsWith(otherAttribute: Attribute<T>) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.expression,
            rightExpression: otherAttribute.expression,
            modifier: .DirectPredicateModifier,
            type: .BeginsWithPredicateOperatorType,
            options: self.comparisonPredicateOptions()
        )
    }

    public func endsWith(value: T) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.expression,
            rightExpression: self.expressionForValue(value),
            modifier: .DirectPredicateModifier,
            type: .EndsWithPredicateOperatorType,
            options: self.comparisonPredicateOptions()
        )
    }

    public func endsWith(otherAttribute: Attribute<T>) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: self.expression,
            rightExpression: otherAttribute.expression,
            modifier: .DirectPredicateModifier,
            type: .EndsWithPredicateOperatorType,
            options: self.comparisonPredicateOptions()
        )
    }

}


// MARK: - Attribute operators

public func ==<T>(left: Attribute<T>, right: T) -> NSComparisonPredicate {
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: left.expressionForValue(right),
        modifier: .DirectPredicateModifier,
        type: .EqualToPredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

public func ==<T>(left: Attribute<T>, right: Attribute<T>) -> NSComparisonPredicate {
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: right.expression,
        modifier: .DirectPredicateModifier,
        type: .EqualToPredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

public func !=<T>(left: Attribute<T>, right: T) -> NSComparisonPredicate {
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: left.expressionForValue(right),
        modifier: .DirectPredicateModifier,
        type: .NotEqualToPredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

public func !=<T>(left: Attribute<T>, right: Attribute<T>) -> NSComparisonPredicate {
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: right.expression,
        modifier: .DirectPredicateModifier,
        type: .NotEqualToPredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

public func ><T>(left: Attribute<T>, right: T) -> NSComparisonPredicate {
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: left.expressionForValue(right),
        modifier: .DirectPredicateModifier,
        type: .GreaterThanPredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

public func ><T>(left: Attribute<T>, right: Attribute<T>) -> NSComparisonPredicate {
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: right.expression,
        modifier: .DirectPredicateModifier,
        type: .GreaterThanPredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

public func >=<T>(left: Attribute<T>, right: T) -> NSComparisonPredicate {
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: left.expressionForValue(right),
        modifier: .DirectPredicateModifier,
        type: .GreaterThanOrEqualToPredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

public func >=<T>(left: Attribute<T>, right: Attribute<T>) -> NSComparisonPredicate {
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: right.expression,
        modifier: .DirectPredicateModifier,
        type: .GreaterThanOrEqualToPredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

public func <<T>(left: Attribute<T>, right: T) -> NSComparisonPredicate {
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: left.expressionForValue(right),
        modifier: .DirectPredicateModifier,
        type: .LessThanPredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

public func <<T>(left: Attribute<T>, right: Attribute<T>) -> NSComparisonPredicate {
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: right.expression,
        modifier: .DirectPredicateModifier,
        type: .LessThanPredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

public func <=<T>(left: Attribute<T>, right: T) -> NSComparisonPredicate {
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: left.expressionForValue(right),
        modifier: .DirectPredicateModifier,
        type: .LessThanOrEqualToPredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

public func <=<T>(left: Attribute<T>, right: Attribute<T>) -> NSComparisonPredicate {
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: right.expression,
        modifier: .DirectPredicateModifier,
        type: .LessThanOrEqualToPredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

public func ~=<T>(left: Attribute<T>, right: T) -> NSComparisonPredicate {
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: left.expressionForValue(right),
        modifier: .DirectPredicateModifier,
        type: .LikePredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

public func <<<T>(left: Attribute<T>, right: [T]) -> NSComparisonPredicate {
    let rightValue = map(right) { $0 as! AnyObject }
    let rightExpression = NSExpression(forConstantValue: rightValue)
    
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: rightExpression,
        modifier: .DirectPredicateModifier,
        type: .InPredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

public func <<<T>(left: Attribute<T>, right: Range<T>) -> NSComparisonPredicate {
    let rightValue = [right.startIndex as! AnyObject, right.endIndex as! AnyObject] as NSArray
    let rightExpression = NSExpression(forConstantValue: rightValue)
    
    return NSComparisonPredicate(
        leftExpression: left.expression,
        rightExpression: rightExpression,
        modifier: .DirectPredicateModifier,
        type: .BetweenPredicateOperatorType,
        options: left.comparisonPredicateOptions()
    )
}

prefix public func !(left: Attribute<Bool>) -> NSComparisonPredicate {
    return left == false
}

// MARK: - NSPredicate extensions

public func &&(left: NSPredicate, right: NSPredicate) -> NSCompoundPredicate {
    return NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [left, right])
}

public func ||(left: NSPredicate, right: NSPredicate) -> NSCompoundPredicate {
    return NSCompoundPredicate(type: NSCompoundPredicateType.OrPredicateType, subpredicates: [left, right])
}

prefix public func !(left: NSPredicate) -> NSCompoundPredicate {
    return NSCompoundPredicate(type: NSCompoundPredicateType.NotPredicateType, subpredicates: [left])
}


// MARK: - Entity attribute support

public class SingleEntityAttribute<T>: Attribute<T> {
    
    public override init(_ name: String) { super.init(name) }
    
}

public class EntitySetAttribute<T>: Attribute<T> {
    
    public override init(_ name: String) { super.init(name) }
    
    public lazy var count: EntitySetCollectionOperatorAttribute<Int> =  EntitySetCollectionOperatorAttribute<Int>(collectionOperator: "@count", entitySetAttributeName: self.___name)
    
}

public class EntitySetCollectionOperatorAttribute<T>: Attribute<T> {
    
    private let entitySetAttributeName: String
    
    public init(collectionOperator: String, entitySetAttributeName: String) {
        self.entitySetAttributeName = entitySetAttributeName
        super.init(collectionOperator)
    }

    private override var expression: NSExpression {
        return NSExpression(forKeyPath: "\(self.entitySetAttributeName).\(self.___name)")
    }
    
}
