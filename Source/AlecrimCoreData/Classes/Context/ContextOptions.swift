//
//  DataContextOptions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-02-26.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public enum StoreType {
    case SQLite
    case InMemory
}

public struct ContextOptions {
    
    // older versions compatibility (will be removed in 4.0)
    public static var stringComparisonPredicateOptions = (NSComparisonPredicateOptions.CaseInsensitivePredicateOption | NSComparisonPredicateOptions.DiacriticInsensitivePredicateOption)
    public static var fetchBatchSize = 20
    
    // MARK: -
    
    public let managedObjectModelURL: NSURL?
    public let persistentStoreURL: NSURL?
    
    // MARK: -
    
    public var storeType: StoreType = .SQLite
    public var configuration: String? = nil
    public let options: NSMutableDictionary = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true]
    
    // MARK: - THE constructor
    
    public init(managedObjectModelURL: NSURL, persistentStoreURL: NSURL) {
        self.managedObjectModelURL = managedObjectModelURL
        self.persistentStoreURL = persistentStoreURL
    }
    
    // MARK: - "convenience" initializers
    
    public init(managedObjectModelURL: NSURL) {
        self.managedObjectModelURL = managedObjectModelURL
        self.persistentStoreURL = ContextOptions.inferredPersistentStoreURL()
    }
    
    public init(persistentStoreURL: NSURL) {
        self.managedObjectModelURL = ContextOptions.inferredManagedObjectModelURL()
        self.persistentStoreURL = persistentStoreURL
    }
    
    public init() {
        self.managedObjectModelURL = ContextOptions.inferredManagedObjectModelURL()
        self.persistentStoreURL = ContextOptions.inferredPersistentStoreURL()
    }
    
    // MARK: - app extension convenience constructors
    
    public init(managedObjectModelBundle: NSBundle, applicationGroupIdentifier: String) {
        self.managedObjectModelURL = ContextOptions.inferredManagedObjectModelURLForBundle(managedObjectModelBundle)
        self.persistentStoreURL = ContextOptions.inferredPersistentStoreURLForApplicationGroupIdentifier(applicationGroupIdentifier)
    }
    
    public init(managedObjectModelBundle: NSBundle) {
        self.managedObjectModelURL = ContextOptions.inferredManagedObjectModelURLForBundle(managedObjectModelBundle)
        self.persistentStoreURL = ContextOptions.inferredPersistentStoreURL()
    }
    
    public init(applicationGroupIdentifier: String) {
        self.managedObjectModelURL = ContextOptions.inferredManagedObjectModelURL()
        self.persistentStoreURL = ContextOptions.inferredPersistentStoreURLForApplicationGroupIdentifier(applicationGroupIdentifier)
    }
    
}


// Ubiquity (iCloud) support has changed in this version.

extension ContextOptions {
    
    public var ubiquityEnabled: Bool {
        return self.storeType == .SQLite && self.options[NSPersistentStoreUbiquitousContainerIdentifierKey] != nil
    }
    
    public func configureUbiquityOptionsWithUbiquitousContainerIdentifier(ubiquitousContainerIdentifier: String, ubiquitousContentURL: NSURL, ubiquitousContentName: String) {
        self.options[NSPersistentStoreUbiquitousContainerIdentifierKey] = ubiquitousContainerIdentifier
        self.options[NSPersistentStoreUbiquitousContentURLKey] = ubiquitousContentURL
        self.options[NSPersistentStoreUbiquitousContentNameKey] = ubiquitousContentName

        self.options[NSMigratePersistentStoresAutomaticallyOption] = true
        self.options[NSInferMappingModelAutomaticallyOption] = true
    }
    
}

extension ContextOptions {
    
    private static func inferredManagedObjectModelName() -> String? {
        return NSBundle.mainBundle().infoDictionary?[String(kCFBundleNameKey)] as? String
    }
    
    private static func inferredManagedObjectModelURLForBundle(bundle: NSBundle) -> NSURL? {
        if let managedObjectModelName = ContextOptions.inferredManagedObjectModelName() {
            return bundle.URLForResource(managedObjectModelName, withExtension: "momd")
        }
        
        return nil
    }
    
    private static func inferredManagedObjectModelURL() -> NSURL? {
        return ContextOptions.inferredManagedObjectModelURLForBundle(NSBundle.mainBundle())
    }
    
}

extension ContextOptions {
    
    private static func inferredPersistentStoreURL() -> NSURL? {
        if let applicationSupportURL = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask).last as? NSURL,
            let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier,
            let managedObjectModelName = ContextOptions.inferredManagedObjectModelName() {
                let url = applicationSupportURL
                    .URLByAppendingPathComponent(bundleIdentifier, isDirectory: true)
                    .URLByAppendingPathComponent("CoreData", isDirectory: true)
                    .URLByAppendingPathComponent(managedObjectModelName.stringByAppendingPathExtension("sqlite")!, isDirectory: false)
                
                return url
        }
        
        
        return nil
    }
    
    private static func inferredPersistentStoreURLForApplicationGroupIdentifier(applicationGroupIdentifier: String) -> NSURL? {
        if let containerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(applicationGroupIdentifier),
            let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier,
            let managedObjectModelName = ContextOptions.inferredManagedObjectModelName() {
                let url = containerURL
                    .URLByAppendingPathComponent("Library", isDirectory: true)
                    .URLByAppendingPathComponent("Application Support", isDirectory: true)
                    .URLByAppendingPathComponent(bundleIdentifier, isDirectory: true)
                    .URLByAppendingPathComponent("CoreData", isDirectory: true)
                    .URLByAppendingPathComponent(managedObjectModelName.stringByAppendingPathExtension("sqlite")!, isDirectory: false)
                
                return url
        }
        
        return nil
    }
    
}


