//
//  Attribute.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-02-25.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: - non nullable attribute

public struct Attribute<T>: AttributeType {
    
    public typealias ValueType = T
    
    public let ___name: String
//    public let ___expression: NSExpression
    
    public init(_ name: String) {
        self.___name = name
//        self.___expression = NSExpression(forKeyPath: self.___name)
    }

    public init(_ name: String, _ parentAttribute: NamedAttributeType) {
        self.___name = parentAttribute.___name + "." + name
//        self.___expression = NSExpression(forKeyPath: self.___name)
    }
    
//    private init(_ name: String, _ expression: NSExpression) {
//        self.___name = name
//        self.___expression = expression
//    }

}

// MARK: nullable (comparable to nil) attribute

public struct NullableAttribute<T>: NullableAttributeType {

    public typealias ValueType = T
    
    public let ___name: String
    
    public init(_ name: String) {
        self.___name = name
    }
    
    public init(_ name: String, _ parentAttribute: NamedAttributeType) {
        self.___name = parentAttribute.___name + "." + name
    }
    
}

// MARK: - Attribute extensions - CollectionType

extension Attribute where T: CollectionType {
    
    public func count() -> Attribute<Int> {
        return Attribute<Int>("@count", self)
    }
    
    public func max<U>(@noescape closure: (T.Generator.Element.Type) -> Attribute<U>) -> Attribute<U> {
        let innerAttribute = closure(T.Generator.Element.self)
        return Attribute<U>("@max." + innerAttribute.___name, self)
    }

    public func min<U>(@noescape closure: (T.Generator.Element.Type) -> Attribute<U>) -> Attribute<U> {
        let innerAttribute = closure(T.Generator.Element.self)
        return Attribute<U>("@min." + innerAttribute.___name, self)
    }
    
    public func avg<U>(@noescape closure: (T.Generator.Element.Type) -> Attribute<U>) -> Attribute<U> {
        let innerAttribute = closure(T.Generator.Element.self)
        return Attribute<U>("@avg." + innerAttribute.___name, self)
    }
    public func sum<U>(@noescape closure: (T.Generator.Element.Type) -> Attribute<U>) -> Attribute<U> {
        let innerAttribute = closure(T.Generator.Element.self)
        return Attribute<U>("@sum." + innerAttribute.___name, self)
    }

}

//extension Attribute where T: CollectionType {
//    
//    public func count(@noescape closure: (Attribute<T.Generator.Element>) -> NSPredicate) -> Attribute<Int> {
//        let expression = NSExpression(forKeyPath: self.___name)
//        let variable = "v"
//        let predicate = closure(Attribute<T.Generator.Element>("$" + variable))
//        
//        let subqueryExpression = NSExpression(forSubquery: expression, usingIteratorVariable: variable, predicate: predicate)
//        let countExpression = NSExpression(format: "%@.@count", argumentArray: [subqueryExpression])
//        
//        print(countExpression.expressionType.rawValue)
//        
//        return Attribute<Int>(countExpression.description, countExpression);
//    }
//
//}
