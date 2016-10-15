//
//  Attribute.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-02-25.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: - non nullable attribute

public struct Attribute<T>: AttributeProtocol {
    
    public typealias ValueType = T
    
    public let ___name: String
    
    public init(_ name: String) {
        self.___name = name
    }

    public init(_ name: String, _ parentAttribute: NamedAttributeProtocol) {
        self.___name = parentAttribute.___name + "." + name
    }
    
}

// MARK: nullable (comparable to nil) attribute

public struct NullableAttribute<T>: NullableAttributeProtocol {

    public typealias ValueType = T
    
    public let ___name: String
    
    public init(_ name: String) {
        self.___name = name
    }
    
    public init(_ name: String, _ parentAttribute: NamedAttributeProtocol) {
        self.___name = parentAttribute.___name + "." + name
    }
    
}

// MARK: - Attribute extensions - CollectionType

extension Attribute where T: Collection {
    
    public func count() -> Attribute<Int> {
        return Attribute<Int>("@count", self)
    }
    
    public func max<U>(_ closure: (T.Iterator.Element.Type) -> Attribute<U>) -> Attribute<U> {
        let innerAttribute = closure(T.Iterator.Element.self)
        return Attribute<U>("@max." + innerAttribute.___name, self)
    }

    public func min<U>(_ closure: (T.Iterator.Element.Type) -> Attribute<U>) -> Attribute<U> {
        let innerAttribute = closure(T.Iterator.Element.self)
        return Attribute<U>("@min." + innerAttribute.___name, self)
    }
    
    public func avg<U>(_ closure: (T.Iterator.Element.Type) -> Attribute<U>) -> Attribute<U> {
        let innerAttribute = closure(T.Iterator.Element.self)
        return Attribute<U>("@avg." + innerAttribute.___name, self)
    }

    public func sum<U>(_ closure: (T.Iterator.Element.Type) -> Attribute<U>) -> Attribute<U> {
        let innerAttribute = closure(T.Iterator.Element.self)
        return Attribute<U>("@sum." + innerAttribute.___name, self)
    }

}
