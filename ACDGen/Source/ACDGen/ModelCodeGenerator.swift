//
//  ModelCodeGenerator.swift
//  ACDGen
//
//  Created by Vanderlei Martinelli on 2015-02-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public final class ModelCodeGenerator: CodeGenerator {
    
    public let parameters: CodeGeneratorParameters
    
    private var tempFileURLs = [NSURL]()
    
    public init(parameters: CodeGeneratorParameters) {
        self.parameters = parameters
    }
    
    deinit {
        if !self.tempFileURLs.isEmpty {
            let fileManager = NSFileManager.defaultManager()
            
            for url in self.tempFileURLs {
                do {
                    try fileManager.removeItemAtURL(url)
                }
                catch {
                }
            }
        }
    }
    
    public func generate() throws {
        let temporaryManagedObjectModel = try self.createTemporaryManagedObjectModel()
        let entityDescriptions = temporaryManagedObjectModel.entities.sort { $0.managedObjectClassName < $1.managedObjectClassName }

        for entityDescription in entityDescriptions {
            // entity file
            let entityCodeGenerator = EntityCodeGenerator(parameters: self.parameters, entityDescription: entityDescription)
            try entityCodeGenerator.generate()
            
            // entity extensions file
            let entityExtensionsCodeGenerator = EntityExtensionsCodeGenerator(parameters: self.parameters, entityDescription: entityDescription)
            try entityExtensionsCodeGenerator.generate()
        }
    }
    
}

// MARK: - file and external tools methods

extension ModelCodeGenerator {

    private func createTemporaryManagedObjectModel() throws -> NSManagedObjectModel {
        let toolPath = "/Applications/Xcode.app/Contents/Developer/usr/bin/momc"
        guard NSFileManager.defaultManager().fileExistsAtPath(toolPath) else { throw CodeGeneratorErrors.MOMCToolNotFound }
        
        var options = ""
        let supportedOptions = ["MOMC_NO_WARNINGS", "MOMC_NO_INVERSE_RELATIONSHIP_WARNINGS", "MOMC_SUPPRESS_INVERSE_TRANSIENT_ERROR"]
        
        for supportedOption in supportedOptions {
            if (NSProcessInfo.processInfo().environment as NSDictionary).objectForKey(supportedOption) != nil {
                options += " -\(supportedOption)"
            }
        }
        
        let tempFileName = (NSUUID().UUIDString as NSString).stringByAppendingPathExtension("mom")!
        let tempFilePath = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent(tempFileName)
        
        guard let tempFileURL = NSURL(string: tempFilePath) else { throw CodeGeneratorErrors.TemporaryManagedObjectModelCreationFailed }
        self.tempFileURLs.append(tempFileURL)
        
        let toolCall = "\(toolPath) \(options) \"\(self.parameters.dataModelFileURL.path!)\" \"\(tempFilePath)\""
        /* let result = */ system(toolCall) // ignore system() result (momc doesn't return any relevent error codes)
        
        guard let mom = NSManagedObjectModel(contentsOfURL: tempFileURL) else { throw CodeGeneratorErrors.MOMCToolCallFailed }
        
        return mom
    }
    
}
