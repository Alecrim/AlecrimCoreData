//
//  EntitySetCollectionOperatorAttribute.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-06-04.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public class EntitySetCollectionOperatorAttribute<T>: Attribute<T> {
    
    private let entitySetAttributeName: String
    
    public init(collectionOperator: String, entitySetAttributeName: String) {
        self.entitySetAttributeName = entitySetAttributeName
        super.init(collectionOperator)
    }
    
    internal override var expression: NSExpression {
        return NSExpression(forKeyPath: "\(self.entitySetAttributeName).\(self.___name)")
    }
    
}
