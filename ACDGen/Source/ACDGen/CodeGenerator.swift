//
//  CodeGenerator.swift
//  ACDGen
//
//  Created by Vanderlei Martinelli on 2015-02-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public protocol CodeGenerator {
    var parameters: CodeGeneratorParameters { get }
    func generate() throws
}

public enum SourceCodeFileType {
    case `class`
    case properties
    case attributes
    
    public func fullName(fromName name: String) -> String {
        let suffix: String
        
        switch self {
        case .class: suffix = "CoreDataClass"
        case .properties: suffix = "CoreDataProperties"
        case .attributes: suffix = "AlecrimCoreDataAttributes"
        }
        
        return "\(name)+\(suffix).swift"
    }
    
    public var canOverwrite: Bool {
        return self != .class
    }
}

extension CodeGenerator {
    
    public func saveSourceCodeFile(withName name: String, contents: String, type: SourceCodeFileType) throws {
        let url = self.parameters.targetFolderURL.appendingPathComponent(type.fullName(fromName: name), isDirectory: false)
        
        let fileManager = FileManager.default
        
        if !type.canOverwrite && fileManager.fileExists(atPath: url.path) {
            return
        }
        
        do {
            try fileManager.removeItem(at: url)
        }
        catch {
        }
        
        try contents.write(to: url, atomically: true, encoding: String.Encoding.utf8)
    }

}

extension CodeGenerator {
    
    public func valueClassName(for attributeDescription: NSAttributeDescription) -> String {
        if self.parameters.useScalarProperties {
            var isUnsigned = false
            for predicate in attributeDescription.validationPredicates as [NSPredicate] {
                if (predicate.predicateFormat as NSString).contains(">= 0") {
                    isUnsigned = true
                    break
                }
            }
            
            switch attributeDescription.attributeType {
            case .integer16AttributeType:
                return (isUnsigned ? "UInt16" : "Int16")
                
            case .integer32AttributeType:
                return (isUnsigned ? "UInt32" : "Int32")
                
            case .integer64AttributeType:
                return (isUnsigned ? "UInt64" : "Int64")
                
            case .doubleAttributeType:
                return "Double"
                
            case .floatAttributeType:
                return "Float"
                
            case .booleanAttributeType:
                return "Bool"
                
            case .stringAttributeType:
                return "String"
                
            case .dateAttributeType:
                return "Date"
                
            case .binaryDataAttributeType:
                return "Data"
                
            default:
                break
            }
        }
        
        if let attributeValueClassName = attributeDescription.attributeValueClassName {
            // If not using scalar but using Swift String
            if attributeDescription.attributeType == .stringAttributeType && self.parameters.useSwiftString {
                return "String"
            }
            else {
                return attributeValueClassName
            }
        }
        else {
            // If your attribute is of NSTransformableAttributeType, the attributeValueClassName must be set or attribute value class must implement NSCopying.
            if attributeDescription.attributeType == .transformableAttributeType {
                return "AnyObject" // "NSCopying"
            }
            else {
                return "AnyObject"
            }
        }
    }
    
    public func canMarkScalarAsOptional(for attributeDescription: NSAttributeDescription) -> Bool {
        if self.parameters.useScalarProperties {
            switch attributeDescription.attributeType {
            case .integer16AttributeType:
                return false
                
            case .integer32AttributeType:
                return false
                
            case .integer64AttributeType:
                return false
                
            case .doubleAttributeType:
                return false
                
            case .floatAttributeType:
                return false
                
            case .booleanAttributeType:
                return false
                
            default:
                return true
            }
        }
        
        return true
    }
    
    public func isInheritedPropertyDescription(_ property: NSPropertyDescription) -> Bool {
        var superentity = property.entity.superentity
        while superentity != nil {
            if (superentity!.properties as NSArray).contains(property) {
                return true
            }
            
            superentity = superentity?.superentity
        }
        
        return false
    }

}

