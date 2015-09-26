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
    
    public init(_ name: String) {
        self.___name = name
    }

    public init(_ name: String, _ parentAttribute: NamedAttributeType) {
        self.___name = parentAttribute.___name + "." + name
    }
    
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

    // same as avg, for convenience
    public func average<U>(@noescape closure: (T.Generator.Element.Type) -> Attribute<U>) -> Attribute<U> {
        let innerAttribute = closure(T.Generator.Element.self)
        return Attribute<U>("@avg." + innerAttribute.___name, self)
    }

    public func sum<U>(@noescape closure: (T.Generator.Element.Type) -> Attribute<U>) -> Attribute<U> {
        let innerAttribute = closure(T.Generator.Element.self)
        return Attribute<U>("@sum." + innerAttribute.___name, self)
    }

}
