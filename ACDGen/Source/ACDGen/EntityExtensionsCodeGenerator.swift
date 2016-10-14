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
    fileprivate let entityDescription: NSEntityDescription
    
    fileprivate let string = NSMutableString()
    
    fileprivate let className: String
    
    fileprivate let attributes: [String : NSAttributeDescription]
    fileprivate let attributeKeys: [String]
    
    fileprivate let relationships: [String : NSRelationshipDescription]
    fileprivate let relationshipKeys: [String]
    
    public init(parameters: CodeGeneratorParameters, entityDescription: NSEntityDescription) {
        //
        self.parameters = parameters
        self.entityDescription = entityDescription
        
        //
        self.className = self.entityDescription.managedObjectClassName.components(separatedBy: ".").last!
        
        //
        self.attributes = self.entityDescription.attributesByName
        self.attributeKeys = self.attributes.keys.sorted { $0 < $1 }
        
        //
        self.relationships = self.entityDescription.relationshipsByName
        self.relationshipKeys = self.relationships.keys.sorted { $0 < $1 }
    }
    
    public func generate() throws {
        try self.generatePropertiesFile()
        
        if self.parameters.generateQueryAttributes {
            try self.generateQueryAttributesFile()
        }
    }
    
    private func generatePropertiesFile() throws {
        self.string.setString("")
        
        self.generateHeader(type: .properties)
        self.generateExtensionHeader()
        self.generateDefaultFetchRequest()
        self.generateAttributes()
        self.generateToOneRelationships()
        self.generateToManyRelationships()
        self.generateFetchedProperties()
        self.generateFetchRequestTemplates()
        self.generateExtensionFooter()
        self.generateFooter()
        
        try self.saveSourceCodeFile(withName: self.className, contents: self.string as String, type: .properties)
    }
    
    private func generateQueryAttributesFile() throws {
        self.string.setString("")
        
        self.generateHeader(type: .attributes)
        
        self.generateClassQueryAttributes()
        self.generateInstanceQueryAttributes()
        
        if self.parameters.dataContextName != "" {
            self.generateDataContextExtension()
        }
        
        self.generateFooter()
        
        try self.saveSourceCodeFile(withName: self.className, contents: self.string as String, type: .attributes)
    }
    
}

extension EntityExtensionsCodeGenerator {
    
    fileprivate func generateHeader(type: SourceCodeFileType) {
        // header
        self.string.appendHeader(self.className, type: type)
        
        // import
        self.string.appendLine("import Foundation")
        self.string.appendLine("import CoreData")
        
        if type == .attributes && (self.parameters.dataContextName != "" || self.parameters.generateQueryAttributes) {
            self.string.appendLine()
            self.string.appendLine("import AlecrimCoreData")
        }
        
        self.string.appendLine()
    }
    
    fileprivate func generateExtensionHeader() {
        self.string.appendLine("// MARK: - \(self.className) properties")
        self.string.appendLine()
        self.string.appendLine("extension \(self.className) {")
        self.string.appendLine()
    }
    
    fileprivate func generateExtensionFooter() {
        self.string.appendLine()
        self.string.appendLine("}")
    }

    
    fileprivate func generateFooter() {
        self.string.appendLine()
    }
    
}

extension EntityExtensionsCodeGenerator {
    
    fileprivate func generateDefaultFetchRequest() {
        self.string.appendLine("@nonobjc " + self.parameters.accessModifier + "class func fetchRequest() -> NSFetchRequest<\(self.className)> {", indentLevel: 1)
        self.string.appendLine("return NSFetchRequest<\(self.className)>(entityName: \"\(self.className)\")", indentLevel: 2)
        self.string.appendLine("}", indentLevel: 1)
        self.string.appendLine()
    }
    
    fileprivate func generateAttributes() {
        for attributeKey in self.attributeKeys {
            let attribute = self.attributes[attributeKey]!
            if self.isInheritedPropertyDescription(attribute) {
                continue
            }
            
            let name = attribute.name
            let valueClassName = self.valueClassName(for: attribute)
            
            if (self.parameters.useScalarProperties && attribute.isOptional && !self.canMarkScalarAsOptional(for: attribute)) {
                self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "var \(name): \(valueClassName) // cannot mark as optional because Objective-C compatibility issues", indentLevel: 1)
            }
            else {
                let optionalStr = (attribute.isOptional ? "?" : "")
                self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "var \(name): \(valueClassName)\(optionalStr)", indentLevel: 1)
            }
        }
    }
    
    fileprivate func generateToOneRelationships() {
        var addedSeparator = false
        
        for relationshipKey in relationshipKeys {
            let relationship = relationships[relationshipKey]!
            if self.isInheritedPropertyDescription(relationship) {
                continue
            }
            
            if !relationship.isToMany {
                if !addedSeparator {
                    self.string.appendLine()
                    addedSeparator = true
                }
                
                let name = relationship.name
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.components(separatedBy: ".").last!
                let optionalStr = (relationship.isOptional ? "?" : "")
                
                self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "var \(name): \(valueClassName)\(optionalStr)", indentLevel: 1)
            }
        }
    }
    
    fileprivate func generateToManyRelationships() {
        var addedSeparator = false
        
        //
        for relationshipKey in self.relationshipKeys {
            let relationship = self.relationships[relationshipKey]!
            if self.isInheritedPropertyDescription(relationship) {
                continue
            }
            
            if relationship.isToMany {
                if !addedSeparator {
                    self.string.appendLine()
                    addedSeparator = true
                }
                
                let name = relationship.name
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.components(separatedBy: ".").last!
                
                if relationship.isOrdered {
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
            
            if relationship.isToMany {
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
                let capitalizedName = (name as NSString).substring(to: 1).uppercased() + (name as NSString).substring(from: 1)
                
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.components(separatedBy: ".").last!
                
                self.string.appendLine("@objc(add\(capitalizedName)Object:)", indentLevel: 1)
                self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "func addTo\(capitalizedName)(_ value: \(valueClassName))", indentLevel: 1)
                self.string.appendLine()
                
                self.string.appendLine("@objc(remove\(capitalizedName)Object:)", indentLevel: 1)
                self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "func removeFrom\(capitalizedName)(_ value: \(valueClassName))", indentLevel: 1)
                self.string.appendLine()
                
                if self.parameters.useScalarProperties {
                    self.string.appendLine("@objc(add\(capitalizedName):)", indentLevel: 1)
                    self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "func addTo\(capitalizedName)(_ values: Set<\(valueClassName)>)", indentLevel: 1)
                    self.string.appendLine()

                    self.string.appendLine("@objc(remove\(capitalizedName):)", indentLevel: 1)
                    self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "func removeFrom\(capitalizedName)(_ values: Set<\(valueClassName)>)", indentLevel: 1)
                }
                else {
                    self.string.appendLine("@objc(add\(capitalizedName):)", indentLevel: 1)
                    self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "func addTo\(capitalizedName)(_ values: NSSet)", indentLevel: 1)
                    self.string.appendLine()

                    self.string.appendLine("@objc(remove\(capitalizedName):)", indentLevel: 1)
                    self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "func removeFrom\(capitalizedName)(_ values: NSSet)", indentLevel: 1)
                }
            }
        }
        
//        //
//        for relationshipKey in self.relationshipKeys {
//            let relationship = self.relationships[relationshipKey]!
//            if self.isInheritedPropertyDescription(relationship) {
//                continue
//            }
//            
//            if relationship.isToMany {
//                self.string.appendLine()
//                
//                let name = relationship.name
//                let capitalizedName = (name as NSString).substring(to: 1).uppercased() + (name as NSString).substring(from: 1)
//                let singularName = name.camelCaseSingularized()
//                let capitalizedSingularName = (singularName as NSString).substring(to: 1).uppercased() + (singularName as NSString).substring(from: 1)
//                
//                let valueClassName = relationship.destinationEntity!.managedObjectClassName.components(separatedBy: ".").last!
//                
//                self.string.appendLine(self.parameters.accessModifier + "func add\(capitalizedSingularName)(\(singularName): \(valueClassName)) { self.add\(capitalizedName)Object(\(singularName)) }", indentLevel: 1)
//                self.string.appendLine(self.parameters.accessModifier + "func remove\(capitalizedSingularName)(\(singularName): \(valueClassName)) { self.remove\(capitalizedName)Object(\(singularName)) }", indentLevel: 1)
//            }
//        }
    }
    
    fileprivate func generateFetchedProperties() {
        var addedSeparator = false
        
        let fetchedProperties = (self.entityDescription.properties.filter({ $0 is NSFetchedPropertyDescription }) as! [NSFetchedPropertyDescription]).sorted { $0.name < $1.name }
        for fetchedProperty in fetchedProperties {
            if self.isInheritedPropertyDescription(fetchedProperty) {
                continue
            }
            
            if !addedSeparator {
                self.string.appendLine()
                addedSeparator = true
            }
            
            let name = fetchedProperty.name
            let valueClassName = fetchedProperty.entity.managedObjectClassName.components(separatedBy: ".").last!
            
            self.string.appendLine("@NSManaged " + self.parameters.accessModifier + "let \(name): [\(valueClassName)]", indentLevel: 1)
        }
    }
    
    fileprivate func generateFetchRequestTemplates() {
        // TODO:
    }
}

extension EntityExtensionsCodeGenerator {
    
    fileprivate func generateClassQueryAttributes() {
        self.generateClassQueryAttributesHeader()
        self.generateClassQueryAttributesForAttributes()
        self.generateClassQueryAttributesForToOneRelationships()
        self.generateClassQueryAttributesForToManyRelationships()
        self.generateClassQueryAttributesFooter()
    }
    
    fileprivate func generateClassQueryAttributesHeader() {
        self.string.appendLine()
        self.string.appendLine("// MARK: - \(self.className) query attributes")
        self.string.appendLine()
        self.string.appendLine("extension \(self.className) {")
        self.string.appendLine()
    }
    
    fileprivate func generateClassQueryAttributesForAttributes() {
        for attributeKey in self.attributeKeys {
            let attribute = self.attributes[attributeKey]!
            if self.isInheritedPropertyDescription(attribute) || attribute.isTransient {
                continue
            }
            
            let name = attribute.name
            let valueClassName = self.valueClassName(for: attribute)
            let attributeClassName = (attribute.isOptional ? CodeGeneratorParameters.nullableAttributeClassName : CodeGeneratorParameters.nonNullableAttributeClassName)
            let optionalStr = "" // (attribute.optional ? "?" : "")
            
            self.string.appendLine(self.parameters.accessModifier + "static let \(name) = \(attributeClassName)<\(valueClassName)\(optionalStr)>(\"\(name)\")", indentLevel: 1)
        }
    }
    
    fileprivate func generateClassQueryAttributesForToOneRelationships() {
        var addedSeparator = false
        
        for relationshipKey in self.relationshipKeys {
            let relationship = self.relationships[relationshipKey]!
            if self.isInheritedPropertyDescription(relationship) || relationship.isTransient {
                continue
            }
            
            if !relationship.isToMany {
                if !addedSeparator {
                    string.appendLine()
                    addedSeparator = true
                }
                
                let name = relationship.name
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.components(separatedBy: ".").last!
                let attributeClassName = (relationship.isOptional ? CodeGeneratorParameters.nullableAttributeClassName : CodeGeneratorParameters.nonNullableAttributeClassName)
                let optionalStr = "" // (relationship.optional ? "?" : "")
                
                self.string.appendLine(self.parameters.accessModifier + "static let \(name) = \(attributeClassName)<\(valueClassName)\(optionalStr)>(\"\(name)\")", indentLevel: 1)
            }
        }
    }
    
    fileprivate func generateClassQueryAttributesForToManyRelationships() {
        var addedSeparator = false
        
        for relationshipKey in self.relationshipKeys {
            let relationship = self.relationships[relationshipKey]!
            if self.isInheritedPropertyDescription(relationship) || relationship.isTransient {
                continue
            }
            
            if relationship.isToMany {
                if !addedSeparator {
                    string.appendLine()
                    addedSeparator = true
                }
                
                let name = relationship.name
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.components(separatedBy: ".").last!
                let attributeClassName = CodeGeneratorParameters.nonNullableAttributeClassName // (relationship.optional ? self.nullableAttributeClassName : self.nonNullableAttributeClassName)
                
                if relationship.isOrdered {
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
    
    fileprivate func generateClassQueryAttributesFooter() {
        string.appendLine()
        string.appendLine("}")
    }
    
}

extension EntityExtensionsCodeGenerator {
    
    fileprivate func generateInstanceQueryAttributes() {
        self.generateInstanceQueryAttributesHeader()
        self.generateInstanceQueryAttributesForAttributes()
        self.generateInstanceQueryAttributesForToOneRelationships()
        self.generateInstanceQueryAttributesForToManyRelationships()
        self.generateInstanceQueryAttributesFooter()
    }
    
    fileprivate func generateInstanceQueryAttributesHeader() {
        self.string.appendLine()
        self.string.appendLine("// MARK: - AttributeProtocol extensions")
        self.string.appendLine()
        self.string.appendLine("extension AlecrimCoreData.AttributeProtocol where Self.ValueType: \(self.className) {")
        self.string.appendLine()
    }
    
    fileprivate func generateInstanceQueryAttributesForAttributes() {
        for attributeKey in self.attributeKeys {
            let attribute = self.attributes[attributeKey]!
            if self.isInheritedPropertyDescription(attribute) || attribute.isTransient {
                continue
            }
            
            let name = attribute.name
            let valueClassName = self.valueClassName(for: attribute)
            let attributeClassName = (attribute.isOptional ? CodeGeneratorParameters.nullableAttributeClassName : CodeGeneratorParameters.nonNullableAttributeClassName)
            let optionalStr = "" // (attribute.optional ? "?" : "")
            
            string.appendLine(self.parameters.accessModifier + "var \(name): \(attributeClassName)<\(valueClassName)\(optionalStr)> { return \(attributeClassName)<\(valueClassName)\(optionalStr)>(\"\(name)\", self) }", indentLevel: 1)
        }
    }
    
    fileprivate func generateInstanceQueryAttributesForToOneRelationships() {
        var addedSeparator = false
        
        for relationshipKey in self.relationshipKeys {
            let relationship = self.relationships[relationshipKey]!
            if self.isInheritedPropertyDescription(relationship) || relationship.isTransient {
                continue
            }
            
            if !relationship.isToMany {
                if !addedSeparator {
                    string.appendLine()
                    addedSeparator = true
                }
                
                let name = relationship.name
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.components(separatedBy: ".").last!
                let attributeClassName = (relationship.isOptional ? CodeGeneratorParameters.nullableAttributeClassName : CodeGeneratorParameters.nonNullableAttributeClassName)
                let optionalStr = "" // (relationship.optional ? "?" : "")
                
                self.string.appendLine(self.parameters.accessModifier + "var \(name): \(attributeClassName)<\(valueClassName)\(optionalStr)> { return \(attributeClassName)<\(valueClassName)\(optionalStr)>(\"\(name)\", self) }", indentLevel: 1)
            }
        }
    }
    
    fileprivate func generateInstanceQueryAttributesForToManyRelationships() {
        var addedSeparator = false
        
        for relationshipKey in self.relationshipKeys {
            let relationship = self.relationships[relationshipKey]!
            if self.isInheritedPropertyDescription(relationship) || relationship.isTransient {
                continue
            }
            
            if relationship.isToMany {
                if !addedSeparator {
                    string.appendLine()
                    addedSeparator = true
                }
                
                let name = relationship.name
                let valueClassName = relationship.destinationEntity!.managedObjectClassName.components(separatedBy: ".").last!
                let attributeClassName = CodeGeneratorParameters.nonNullableAttributeClassName // (relationship.optional ? self.nullableAttributeClassName : self.nonNullableAttributeClassName)
                
                if relationship.isOrdered {
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
    
    fileprivate func generateInstanceQueryAttributesFooter() {
        self.string.appendLine()
        self.string.appendLine("}")
    }

}

extension EntityExtensionsCodeGenerator {
    
    fileprivate func generateDataContextExtension() {
        // begin
        self.string.appendLine()
        self.string.appendLine("// MARK: - \(self.parameters.dataContextName) extensions")
        self.string.appendLine()
        self.string.appendLine("extension \(self.parameters.dataContextName) {")
        self.string.appendLine()
        
        // entity
        let propertyName = self.entityDescription.name!.camelCasePluralized()
        self.string.appendLine(self.parameters.accessModifier + "var \(propertyName): AlecrimCoreData.Table<\(self.className)> { return AlecrimCoreData.Table<\(self.className)>(context: self) }", indentLevel: 1)
        
        // end
        self.string.appendLine()
        self.string.appendLine("}")
    }
    
}
