//
//  Attribute.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-02-25.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

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

extension Attribute where T: CollectionType {
    
    public var count: Attribute<Int> {
        return Attribute<Int>(self.___name + ".@count")
    }
    
}
