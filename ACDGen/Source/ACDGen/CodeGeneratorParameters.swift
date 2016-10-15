//
//  CodeGeneratorParameters.swift
//  ACDGen
//
//  Created by Vanderlei Martinelli on 2015-02-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public struct CodeGeneratorParameters {
    
    public static let nonNullableAttributeClassName = "AlecrimCoreData.Attribute"
    public static let nullableAttributeClassName = "AlecrimCoreData.NullableAttribute"
    
    public let dataModelFileURL: URL
    public let targetFolderURL: URL
    public let dataContextName: String
    public let useScalarProperties: Bool
    public let useSwiftString: Bool
    public let generateQueryAttributes: Bool
    public let addPublicAccessModifier: Bool
    
    public var accessModifier: String {
        return (self.addPublicAccessModifier ? "public " : "")
    }

}
