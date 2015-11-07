//
//  EntityCodeGenerator.swift
//  ACDGen
//
//  Created by Vanderlei Martinelli on 2015-02-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public final class EntityCodeGenerator: CodeGenerator {
    
    public let parameters: CodeGeneratorParameters
    private let entityDescription: NSEntityDescription
    
    public init(parameters: CodeGeneratorParameters, entityDescription: NSEntityDescription) {
        self.parameters = parameters
        self.entityDescription = entityDescription
    }
    
    public func generate() throws {
        let string = NSMutableString()
        
        //
        let className = self.entityDescription.managedObjectClassName.componentsSeparatedByString(".").last!
        
        // header
        string.appendHeader(className, generated: false)
        
        // import
        string.appendLine("import Foundation")
        string.appendLine("import CoreData")
        string.appendLine()
        
        // class
        let superClassName = (self.entityDescription.superentity == nil ? "NSManagedObject" : self.entityDescription.superentity!.managedObjectClassName.componentsSeparatedByString(".").last!)
        
        string.appendLine(self.parameters.accessModifier + "class \(className): \(superClassName) {")
        string.appendLine()
        string.appendLine("}")
        string.appendLine()
        
        // save
        try self.saveSourceCodeFileWithName(className, contents: string as String, generated: false)
    }
}
