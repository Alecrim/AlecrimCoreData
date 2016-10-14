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
    
    fileprivate var tempFileURLs = [URL]()
    
    public init(parameters: CodeGeneratorParameters) {
        self.parameters = parameters
    }
    
    deinit {
        if !self.tempFileURLs.isEmpty {
            let fileManager = FileManager.default
            
            for url in self.tempFileURLs {
                do {
                    try fileManager.removeItem(at: url)
                }
                catch {
                }
            }
        }
    }
    
    public func generate() throws {
        //
        if self.parameters.dataContextName != "" {
            let dataContextContextGenerator = DataContextCodeGenerator(parameters: self.parameters)
            try dataContextContextGenerator.generate()
        }
        
        //
        let temporaryManagedObjectModel = try self.createTemporaryManagedObjectModel()
        let entityDescriptions = temporaryManagedObjectModel.entities.sorted { $0.managedObjectClassName < $1.managedObjectClassName }

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

    fileprivate func createTemporaryManagedObjectModel() throws -> NSManagedObjectModel {
        let launchPath = "/Applications/Xcode.app/Contents/Developer/usr/bin/momc"
        guard FileManager.default.fileExists(atPath: launchPath) else { throw CodeGeneratorError.momcToolNotFound }
        
        var arguments = [String]()
        let supportedOptions = ["MOMC_NO_WARNINGS", "MOMC_NO_INVERSE_RELATIONSHIP_WARNINGS", "MOMC_SUPPRESS_INVERSE_TRANSIENT_ERROR"]
        
        for supportedOption in supportedOptions {
            if (ProcessInfo.processInfo.environment as NSDictionary).object(forKey: supportedOption) != nil {
                arguments.append("-\(supportedOption)")
            }
        }
        
        let tempFileName = (UUID().uuidString as NSString).appendingPathExtension("mom")!
        let tempFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(tempFileName)
        
        guard let tempFileURL = URL(string: tempFilePath) else { throw CodeGeneratorError.temporaryManagedObjectModelCreationFailed }
        self.tempFileURLs.append(tempFileURL)
        
        arguments.append(self.parameters.dataModelFileURL.path)
        arguments.append(tempFilePath)
        
        let task = Process.launchedProcess(launchPath: launchPath, arguments: arguments)
        task.waitUntilExit()
        guard task.terminationStatus == 0 else { throw CodeGeneratorError.momcToolCallFailed }
        
        guard let mom = NSManagedObjectModel(contentsOf: tempFileURL) else { throw CodeGeneratorError.momcToolCallFailed }
        
        return mom
    }
    
}
