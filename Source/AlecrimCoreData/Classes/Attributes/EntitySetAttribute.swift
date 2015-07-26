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
        // *** METHOD 1 *** //
        // Doesn't work because Core Data bug with NONE (Filled out Apple bug # 21994962)
        // http://stackoverflow.com/a/14473445/235334
        //let p = self.all(predicateClosure)
        //let format = "NONE" + (p.description as NSString).substringFromIndex(3)
        //return NSPredicate(format: format)
        
        // *** METHOD 2 *** //
        // Doesn't work probably because same Core Data bug with NONE above
        // http://stackoverflow.com/questions/6866950
        // Although close, where is the NSComparisonPredicateModifier.NonePredicateModifier?
        //let p = self.any(predicateClosure)
        //return NSCompoundPredicate.notPredicateWithSubpredicate(p)
        
        // *** METHOD 3 *** //
        // This is really super ugly but works
        let p = self.all(predicateClosure)
        let pFormat = (p.description as NSString).substringFromIndex(3)
            .stringByReplacingOccurrencesOfString(
                self.___name, withString: "$o", options: .LiteralSearch, range: nil)
        
        let format = "SUBQUERY(\(self.___name), $o, \(pFormat)).@count == 0"
        
        return NSPredicate(format: format)
    }
    
}
