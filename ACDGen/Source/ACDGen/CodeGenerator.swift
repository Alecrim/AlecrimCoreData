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

extension CodeGenerator {
    
    public func saveSourceCodeFileWithName(name: String, contents: String, generated: Bool) throws {
        let generatedString = (generated ? ".generated" : "")
        let url = self.parameters.targetFolderURL.URLByAppendingPathComponent("\(name)\(generatedString).swift", isDirectory: false)
        
        let fileManager = NSFileManager.defaultManager()
        
        if !generated && fileManager.fileExistsAtPath(url.path!) {
            return
        }
        
        do {
            try fileManager.removeItemAtURL(url)
        }
        catch {
        }
        
        try contents.writeToURL(url, atomically: true, encoding: NSUTF8StringEncoding)
    }

}

extension CodeGenerator {
    
    public func valueClassNameForAttributeDescription(attributeDescription: NSAttributeDescription) -> String {
        if self.parameters.useScalarProperties {
            var isUnsigned = false
            for predicate in attributeDescription.validationPredicates as [NSPredicate] {
                if (predicate.predicateFormat as NSString).containsString(">= 0") {
                    isUnsigned = true
                    break
                }
            }
            
            switch attributeDescription.attributeType {
            case .Integer16AttributeType:
                return (isUnsigned ? "UInt16" : "Int16")
                
            case .Integer32AttributeType:
                return (isUnsigned ? "UInt32" : "Int32")
                
            case .Integer64AttributeType:
                return (isUnsigned ? "UInt64" : "Int64")
                
            case .DoubleAttributeType:
                return "Double"
                
            case .FloatAttributeType:
                return "Float"
                
            case .BooleanAttributeType:
                return "Bool"
                
            case .StringAttributeType:
                return "String"
                
            default:
                break
            }
        }
        
        if let attributeValueClassName = attributeDescription.attributeValueClassName {
            // If not using scalar but using Swift String
            if attributeDescription.attributeType == .StringAttributeType && self.parameters.useSwiftString {
                return "String"
            }
            else {
                return attributeValueClassName
            }
        }
        else {
            // If your attribute is of NSTransformableAttributeType, the attributeValueClassName must be set or attribute value class must implement NSCopying.
            if attributeDescription.attributeType == .TransformableAttributeType {
                return "AnyObject" // "NSCopying"
            }
            else {
                return "AnyObject"
            }
        }
    }
    
    public func canMarkScalarAsOptionalForAttributeDescription(attributeDescription: NSAttributeDescription) -> Bool {
        if self.parameters.useScalarProperties {
            switch attributeDescription.attributeType {
            case .Integer16AttributeType:
                return false
                
            case .Integer32AttributeType:
                return false
                
            case .Integer64AttributeType:
                return false
                
            case .DoubleAttributeType:
                return false
                
            case .FloatAttributeType:
                return false
                
            case .BooleanAttributeType:
                return false
                
            default:
                return true
            }
        }
        
        return true
    }
    
    public func isInheritedPropertyDescription(property: NSPropertyDescription) -> Bool {
        var superentity = property.entity.superentity
        while superentity != nil {
            if (superentity!.properties as NSArray).containsObject(property) {
                return true
            }
            
            superentity = superentity?.superentity
        }
        
        return false
    }

}

