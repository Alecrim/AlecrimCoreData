//
//  EntityExtensionsCodeGenerator.swift
//  ACDGen
//
//  Created by Vanderlei Martinelli on 2015-02-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public final class EntityExtensionsCodeGenerator: CodeGenerator {
    
    public let parameters: CodeGeneratorParameters
    private let entityDescription: NSEntityDescription
    
    private let string = NSMutableString()
    
    private let className: String
    
    private let attributes: [String : NSAttributeDescription]
    private let attributeKeys: [String]
    
    private let relationships: [String : NSRelationshipDescription]
    private let relationshipKeys: [String]
    
    public init(parameters: CodeGeneratorParameters, entityDescription: NSEntityDescription) {
        //
        self.parameters = parameters
        self.entityDescription = entityDescription
        
        //
        self.className = self.entityDescription.managedObjectClassName.componentsSeparatedByString(".").last!
        
        //
        self.attributes = self.entityDescription.attributesByName
        self.attributeKeys = self.attributes.keys.sort({ $0 < $1 })
        
        //
        self.relationships = self.entityDescription.relationshipsByName
        self.relationshipKeys = self.relationships.keys.sort({ $0 < $1 })
    }
    
    public func generate() throws {
        // entity
        self.generateHeader()
        self.generateAttributes()
        self.generateToOneRelationships()
        self.generateToManyRelationships()
        self.generateFetchedProperties()
        self.generateFetchRequestTemplates()
        self.generateFooter()
        
        // query attributes
        if self.parameters.generateQueryAttributes {
            self.generateClassQueryAttributes()
            self.generateInstanceQueryAttributes()
        }
        
        // data context extension
        if self.parameters.dataContextName != "" {
            self.generateDataContextExtension()
        }
        
        // one more line
        self.string.appendLine()
        
        // save
        try self.saveSourceCodeFileWithName(self.className, contents: self.string as String, generated: true)
    }
    
}

extension EntityExtensionsCodeGenerator {
    
    private func generateHeader() {
        // header
        self.string.appendHeader(self.className, generated: true)
        
        // import
        self.string.appendLine("import Foundation")
        self.string.appendLine("import CoreData")
        
        if self.parameters.dataContextName != "" || self.parameters.generateQueryAttributes {
            self.string.appendLine()
            self.string.appendLine("import AlecrimCoreData")
        }
        
        self.string.appendLine()
        
        // extension declaration
        self.string.appendLine("// MARK: - \(self.className) properties")
        self.string.appendLine()
        self.string.appendLine("extension \(self.className) {")
        self.string.appendLine()
    }
    
    private func generateFooter() {
        self.string.appendLine()
        self.string.appendLine("}")
    }
    
}

extension EntityExtensionsCodeGenerator {
    
    private func generateAttributes() {
        for attributeKey in self.attributeKeys {
            let attribute = self.attributes[attributeKey]!
            if self.isInheritedPropertyDescription(attribute) {
                continue
            }
            
            let name = attribute.name
            let valueClassName = self.valueClassNameForAttributeDescription(attribute)
            
            if (self.parameters.useScalarProperties && attribute.optional && !self.canMarkScalarAsOptionalForAttributeDescription(attribute)) {
                self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "var \(name): \(valueClassName) // cannot mark as optional because Objective-C compatibility issues", indentLevel: 1)
            }
            else {
                let optionalStr = (attribute.optional ? "?" : "")
                self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "var \(name): \(valueClassName)\(optionalStr)", indentLevel: 1)
            }
        }
    }
    
    private func generateToOneRelationships() {
        var addedSeparator = false
        
        for relationshipKey in relationshipKeys {
            let relationship = relationships[relationshipKey]!
            if self.isInheritedPropertyDescription(relationship) {
                continue
            }
            
            if !relationship.toMany {
                if !addedSeparator {
                    self.string.appendLine()
                    addedSeparator = true
                }
                
                let name = relationship.name
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.componentsSeparatedByString(".").last!
                let optionalStr = (relationship.optional ? "?" : "")
                
                self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "var \(name): \(valueClassName)\(optionalStr)", indentLevel: 1)
            }
        }
    }
    
    private func generateToManyRelationships() {
        var addedSeparator = false
        
        //
        for relationshipKey in self.relationshipKeys {
            let relationship = self.relationships[relationshipKey]!
            if self.isInheritedPropertyDescription(relationship) {
                continue
            }
            
            if relationship.toMany {
                if !addedSeparator {
                    self.string.appendLine()
                    addedSeparator = true
                }
                
                let name = relationship.name
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.componentsSeparatedByString(".").last!
                
                if relationship.ordered {
                    if self.parameters.useScalarProperties {
                        self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "var \(name): NSOrderedSet // Swift does not have an OrderedSet<> yet", indentLevel: 1)
                    }
                    else {
                        self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "var \(name): NSOrderedSet", indentLevel: 1)
                    }
                }
                else {
                    if self.parameters.useScalarProperties {
                        self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "var \(name): Set<\(valueClassName)>", indentLevel: 1)
                    }
                    else {
                        self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "var \(name): NSSet", indentLevel: 1)
                    }
                }
            }
        }
        
        //
        addedSeparator = false
        for relationshipKey in self.relationshipKeys {
            let relationship = self.relationships[relationshipKey]!
            if self.isInheritedPropertyDescription(relationship) {
                continue
            }
            
            if relationship.toMany {
                if !addedSeparator {
                    self.string.appendLine()
                    self.string.appendLine("}")
                    self.string.appendLine()
                    self.string.appendLine("// MARK: - \(self.className) KVC compliant to-many accessors and helpers")
                    self.string.appendLine()
                    self.string.appendLine("extension \(self.className) {")
                    addedSeparator = true
                }
                
                self.string.appendLine()
                
                let name = relationship.name
                let capitalizedName = (name as NSString).substringToIndex(1).uppercaseString + (name as NSString).substringFromIndex(1)
                
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.componentsSeparatedByString(".").last!
                
                self.string.appendLine("@NSManaged " + "private " + "func add\(capitalizedName)Object(object: \(valueClassName))", indentLevel: 1)
                self.string.appendLine("@NSManaged " + "private " + "func remove\(capitalizedName)Object(object: \(valueClassName))", indentLevel: 1)
                
                if self.parameters.useScalarProperties {
                    self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "func add\(capitalizedName)(\(name): Set<\(valueClassName)>)", indentLevel: 1)
                    self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "func remove\(capitalizedName)(\(name): Set<\(valueClassName)>)", indentLevel: 1)
                }
                else {
                    self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "func add\(capitalizedName)(\(name): NSSet)", indentLevel: 1)
                    self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "func remove\(capitalizedName)(\(name): NSSet)", indentLevel: 1)
                }
            }
        }
        
        //
        for relationshipKey in self.relationshipKeys {
            let relationship = self.relationships[relationshipKey]!
            if self.isInheritedPropertyDescription(relationship) {
                continue
            }
            
            if relationship.toMany {
                self.string.appendLine()
                
                let name = relationship.name
                let capitalizedName = (name as NSString).substringToIndex(1).uppercaseString + (name as NSString).substringFromIndex(1)
                let singularName = name.camelCaseSingularized()
                let capitalizedSingularName = (singularName as NSString).substringToIndex(1).uppercaseString + (singularName as NSString).substringFromIndex(1)
                
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.componentsSeparatedByString(".").last!
                
                self.string.appendLine(self.parameters.accessModifier + "func add\(capitalizedSingularName)(\(singularName): \(valueClassName)) { self.add\(capitalizedName)Object(\(singularName)) }", indentLevel: 1)
                self.string.appendLine(self.parameters.accessModifier + "func remove\(capitalizedSingularName)(\(singularName): \(valueClassName)) { self.remove\(capitalizedName)Object(\(singularName)) }", indentLevel: 1)
            }
        }
    }
    
    private func generateFetchedProperties() {
        var addedSeparator = false
        
        let fetchedProperties = (self.entityDescription.properties.filter({ $0 is NSFetchedPropertyDescription }) as! [NSFetchedPropertyDescription]).sort { $0.name < $1.name }
        for fetchedProperty in fetchedProperties {
            if self.isInheritedPropertyDescription(fetchedProperty) {
                continue
            }
            
            if !addedSeparator {
                self.string.appendLine()
                addedSeparator = true
            }
            
            let name = fetchedProperty.name
            let valueClassName = fetchedProperty.entity.managedObjectClassName.componentsSeparatedByString(".").last!
            
            self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "let \(name): [\(valueClassName)]", indentLevel: 1)
        }
    }
    
    private func generateFetchRequestTemplates() {
        // TODO:
    }
}

extension EntityExtensionsCodeGenerator {
    
    private func generateClassQueryAttributes() {
        self.generateClassQueryAttributesHeader()
        self.generateClassQueryAttributesForAttributes()
        self.generateClassQueryAttributesForToOneRelationships()
        self.generateClassQueryAttributesForToManyRelationships()
        self.generateClassQueryAttributesFooter()
    }
    
    private func generateClassQueryAttributesHeader() {
        self.string.appendLine()
        self.string.appendLine("// MARK: - \(self.className) query attributes")
        self.string.appendLine()
        self.string.appendLine("extension \(self.className) {")
        self.string.appendLine()
    }
    
    private func generateClassQueryAttributesForAttributes() {
        for attributeKey in self.attributeKeys {
            let attribute = self.attributes[attributeKey]!
            if self.isInheritedPropertyDescription(attribute) || attribute.transient {
                continue
            }
            
            let name = attribute.name
            let valueClassName = self.valueClassNameForAttributeDescription(attribute)
            let attributeClassName = (attribute.optional ? CodeGeneratorParameters.nullableAttributeClassName : CodeGeneratorParameters.nonNullableAttributeClassName)
            let optionalStr = "" // (attribute.optional ? "?" : "")
            
            self.string.appendLine(self.parameters.accessModifier + "static let \(name) = \(attributeClassName)<\(valueClassName)\(optionalStr)>(\"\(name)\")", indentLevel: 1)
        }
    }
    
    private func generateClassQueryAttributesForToOneRelationships() {
        var addedSeparator = false
        
        for relationshipKey in self.relationshipKeys {
            let relationship = self.relationships[relationshipKey]!
            if self.isInheritedPropertyDescription(relationship) || relationship.transient {
                continue
            }
            
            if !relationship.toMany {
                if !addedSeparator {
                    string.appendLine()
                    addedSeparator = true
                }
                
                let name = relationship.name
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.componentsSeparatedByString(".").last!
                let attributeClassName = (relationship.optional ? CodeGeneratorParameters.nullableAttributeClassName : CodeGeneratorParameters.nonNullableAttributeClassName)
                let optionalStr = "" // (relationship.optional ? "?" : "")
                
                self.string.appendLine(self.parameters.accessModifier + "static let \(name) = \(attributeClassName)<\(valueClassName)\(optionalStr)>(\"\(name)\")", indentLevel: 1)
            }
        }
    }
    
    private func generateClassQueryAttributesForToManyRelationships() {
        var addedSeparator = false
        
        for relationshipKey in self.relationshipKeys {
            let relationship = self.relationships[relationshipKey]!
            if self.isInheritedPropertyDescription(relationship) || relationship.transient {
                continue
            }
            
            if relationship.toMany {
                if !addedSeparator {
                    string.appendLine()
                    addedSeparator = true
                }
                
                let name = relationship.name
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.componentsSeparatedByString(".").last!
                let attributeClassName = CodeGeneratorParameters.nonNullableAttributeClassName // (relationship.optional ? self.nullableAttributeClassName : self.nonNullableAttributeClassName)
                
                if relationship.ordered {
                    self.string.appendLine(self.parameters.accessModifier + "static let \(name) = \(attributeClassName)<NSOrderedSet>(\"\(name)\")", indentLevel: 1)
                }
                else {
                    if self.parameters.useScalarProperties {
                        self.string.appendLine(self.parameters.accessModifier + "static let \(name) = \(attributeClassName)<Set<\(valueClassName)>>(\"\(name)\")", indentLevel: 1)
                    }
                    else {
                        self.string.appendLine(self.parameters.accessModifier + "static let \(name) = \(attributeClassName)<NSSet>(\"\(name)\")", indentLevel: 1)
                    }
                }
            }
        }
    }
    
    private func generateClassQueryAttributesFooter() {
        string.appendLine()
        string.appendLine("}")
    }
    
}

extension EntityExtensionsCodeGenerator {
    
    private func generateInstanceQueryAttributes() {
        self.generateInstanceQueryAttributesHeader()
        self.generateInstanceQueryAttributesForAttributes()
        self.generateInstanceQueryAttributesForToOneRelationships()
        self.generateInstanceQueryAttributesForToManyRelationships()
        self.generateInstanceQueryAttributesFooter()
    }
    
    private func generateInstanceQueryAttributesHeader() {
        self.string.appendLine()
        self.string.appendLine("// MARK: - AttributeType extensions")
        self.string.appendLine()
        self.string.appendLine("extension AlecrimCoreData.AttributeType where Self.ValueType: \(self.className) {")
        self.string.appendLine()
    }
    
    private func generateInstanceQueryAttributesForAttributes() {
        for attributeKey in self.attributeKeys {
            let attribute = self.attributes[attributeKey]!
            if self.isInheritedPropertyDescription(attribute) || attribute.transient {
                continue
            }
            
            let name = attribute.name
            let valueClassName = self.valueClassNameForAttributeDescription(attribute)
            let attributeClassName = (attribute.optional ? CodeGeneratorParameters.nullableAttributeClassName : CodeGeneratorParameters.nonNullableAttributeClassName)
            let optionalStr = "" // (attribute.optional ? "?" : "")
            
            string.appendLine(self.parameters.accessModifier + "var \(name): \(attributeClassName)<\(valueClassName)\(optionalStr)> { return \(attributeClassName)<\(valueClassName)\(optionalStr)>(\"\(name)\", self) }", indentLevel: 1)
        }
    }
    
    private func generateInstanceQueryAttributesForToOneRelationships() {
        var addedSeparator = false
        
        for relationshipKey in self.relationshipKeys {
            let relationship = self.relationships[relationshipKey]!
            if self.isInheritedPropertyDescription(relationship) || relationship.transient {
                continue
            }
            
            if !relationship.toMany {
                if !addedSeparator {
                    string.appendLine()
                    addedSeparator = true
                }
                
                let name = relationship.name
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.componentsSeparatedByString(".").last!
                let attributeClassName = (relationship.optional ? CodeGeneratorParameters.nullableAttributeClassName : CodeGeneratorParameters.nonNullableAttributeClassName)
                let optionalStr = "" // (relationship.optional ? "?" : "")
                
                self.string.appendLine(self.parameters.accessModifier + "var \(name): \(attributeClassName)<\(valueClassName)\(optionalStr)> { return \(attributeClassName)<\(valueClassName)\(optionalStr)>(\"\(name)\", self) }", indentLevel: 1)
            }
        }
    }
    
    private func generateInstanceQueryAttributesForToManyRelationships() {
        var addedSeparator = false
        
        for relationshipKey in self.relationshipKeys {
            let relationship = self.relationships[relationshipKey]!
            if self.isInheritedPropertyDescription(relationship) || relationship.transient {
                continue
            }
            
            if relationship.toMany {
                if !addedSeparator {
                    string.appendLine()
                    addedSeparator = true
                }
                
                let name = relationship.name
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.componentsSeparatedByString(".").last!
                let attributeClassName = CodeGeneratorParameters.nonNullableAttributeClassName // (relationship.optional ? self.nullableAttributeClassName : self.nonNullableAttributeClassName)
                
                if relationship.ordered {
                    self.string.appendLine(self.parameters.accessModifier + "var \(name): \(attributeClassName)<NSOrderedSet> { return \(attributeClassName)<NSOrderedSet>(\"\(name)\", self) }", indentLevel: 1)
                }
                else {
                    if self.parameters.useScalarProperties {
                        self.string.appendLine(self.parameters.accessModifier + "var \(name): \(attributeClassName)<Set<\(valueClassName)>> { return \(attributeClassName)<Set<\(valueClassName)>>(\"\(name)\", self) }", indentLevel: 1)
                    }
                    else {
                        self.string.appendLine(self.parameters.accessModifier + "var \(name): \(attributeClassName)<NSSet> { return \(attributeClassName)<NSSet>(\"\(name)\", self) }", indentLevel: 1)
                    }
                }
            }
        }
    }
    
    private func generateInstanceQueryAttributesFooter() {
        self.string.appendLine()
        self.string.appendLine("}")
    }

}

extension EntityExtensionsCodeGenerator {
    
    private func generateDataContextExtension() {
        // begin
        self.string.appendLine()
        self.string.appendLine("// MARK: - \(self.parameters.dataContextName) extensions")
        self.string.appendLine()
        self.string.appendLine("extension \(self.parameters.dataContextName) {")
        self.string.appendLine()
        
        // entity
        let propertyName = self.entityDescription.name!.camelCasePluralized()
        self.string.appendLine(self.parameters.accessModifier + "var \(propertyName): AlecrimCoreData.Table<\(self.className)> { return AlecrimCoreData.Table<\(self.className)>(dataContext: self) }", indentLevel: 1)
        
        // end
        self.string.appendLine()
        self.string.appendLine("}")
    }
    
}
