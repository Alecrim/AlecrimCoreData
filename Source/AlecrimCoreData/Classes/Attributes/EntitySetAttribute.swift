//
//  EntitySetAttribute.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-06-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public class EntitySetAttribute<T: CollectionType>: Attribute<T> {
    
    public override init(_ name: String) { super.init(name) }
    
    public lazy var count: EntitySetCollectionOperatorAttribute<Int> = EntitySetCollectionOperatorAttribute<Int>(collectionOperator: "@count", entitySetAttributeName: self.___name)
    
    public func any(predicateClosure: (T.Generator.Element.Type) -> NSComparisonPredicate) -> NSComparisonPredicate {
        let p = predicateClosure(T.Generator.Element.self)
        
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
    
    public func some(predicateClosure: (T.Generator.Element.Type) -> NSComparisonPredicate) -> NSComparisonPredicate {
        return self.any(predicateClosure)
    }
    
    public func all(predicateClosure: (T.Generator.Element.Type) -> NSComparisonPredicate) -> NSComparisonPredicate {
        let p = predicateClosure(T.Generator.Element.self)
        
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
    
    public func none(predicateClosure: (T.Generator.Element.Type) -> NSComparisonPredicate) -> NSPredicate {
        let p = self.all(predicateClosure)
        
        // this is really ugly! (where is the NSComparisonPredicateModifier.NonePredicateModifier?)
        // TODO: find a better way to do this
        let format = "NONE" + (p.description as NSString).substringFromIndex(3)
        
        //
        return NSPredicate(format: format)
    }
    
}
