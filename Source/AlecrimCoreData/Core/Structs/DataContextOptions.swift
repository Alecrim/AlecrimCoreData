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

public struct DataContextOptions {

    // MARK: -

    public let managedObjectModelURL: NSURL?
    public let persistentStoreURL: NSURL?
    
    // MARK: -
    
    public var storeType: StoreType = .SQLite
    public var configuration: String? = nil
    public var options: [NSObject : AnyObject] = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true]
    
    // MARK: - THE constructor
    
    public init(managedObjectModelURL: NSURL, persistentStoreURL: NSURL) {
        self.managedObjectModelURL = managedObjectModelURL
        self.persistentStoreURL = persistentStoreURL
    }
    
    // MARK: - "convenience" initializers
    
    public init(managedObjectModelURL: NSURL) {
        self.managedObjectModelURL = managedObjectModelURL
        self.persistentStoreURL = DataContextOptions.inferredPersistentStoreURL()
    }
    
    public init(persistentStoreURL: NSURL) {
        self.managedObjectModelURL = DataContextOptions.inferredManagedObjectModelURL()
        self.persistentStoreURL = persistentStoreURL
    }
    
    public init() {
        self.managedObjectModelURL = DataContextOptions.inferredManagedObjectModelURL()
        self.persistentStoreURL = DataContextOptions.inferredPersistentStoreURL()
    }
    
    // MARK: - app extension convenience constructors
    
    public init(managedObjectModelBundle: NSBundle, applicationGroupIdentifier: String) {
        self.managedObjectModelURL = DataContextOptions.inferredManagedObjectModelURLForBundle(managedObjectModelBundle)
        self.persistentStoreURL = DataContextOptions.inferredPersistentStoreURLForApplicationGroupIdentifier(applicationGroupIdentifier)
    }
    
    public init(managedObjectModelBundle: NSBundle) {
        self.managedObjectModelURL = DataContextOptions.inferredManagedObjectModelURLForBundle(managedObjectModelBundle)
        self.persistentStoreURL = DataContextOptions.inferredPersistentStoreURL()
    }
    
    public init(applicationGroupIdentifier: String) {
        self.managedObjectModelURL = DataContextOptions.inferredManagedObjectModelURL()
        self.persistentStoreURL = DataContextOptions.inferredPersistentStoreURLForApplicationGroupIdentifier(applicationGroupIdentifier)
    }
    
}

extension DataContextOptions {
    
    #if os(OSX) || os(iOS)
    
    public var ubiquityEnabled: Bool {
        return self.storeType == .SQLite && self.options[NSPersistentStoreUbiquitousContainerIdentifierKey] != nil
    }
    
    public mutating func configureUbiquityOptionsWithUbiquitousContainerIdentifier(ubiquitousContainerIdentifier: String, ubiquitousContentURL: NSURL, ubiquitousContentName: String) {
        self.options[NSPersistentStoreUbiquitousContainerIdentifierKey] = ubiquitousContainerIdentifier
        self.options[NSPersistentStoreUbiquitousContentURLKey] = ubiquitousContentURL
        self.options[NSPersistentStoreUbiquitousContentNameKey] = ubiquitousContentName
        
        self.options[NSMigratePersistentStoresAutomaticallyOption] = true
        self.options[NSInferMappingModelAutomaticallyOption] = true
    }
 
    #endif
}

extension DataContextOptions {
    
    private static func inferredManagedObjectModelName() -> String? {
        return NSBundle.mainBundle().infoDictionary?[String(kCFBundleNameKey)] as? String
    }
    
    private static func inferredManagedObjectModelURLForBundle(bundle: NSBundle) -> NSURL? {
        guard let managedObjectModelName = DataContextOptions.inferredManagedObjectModelName() else { return nil }
        
        return bundle.URLForResource(managedObjectModelName, withExtension: "momd")
    }
    
    private static func inferredManagedObjectModelURL() -> NSURL? {
        return DataContextOptions.inferredManagedObjectModelURLForBundle(NSBundle.mainBundle())
    }
    
}

extension DataContextOptions {
    
    private static func inferredPersistentStoreURL() -> NSURL? {
        guard
            let applicationSupportURL = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask).last,
            let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier,
            let managedObjectModelName = DataContextOptions.inferredManagedObjectModelName()
        else {
            return nil
        }
        
        let url = applicationSupportURL
            .URLByAppendingPathComponent(bundleIdentifier, isDirectory: true)
            .URLByAppendingPathComponent("CoreData", isDirectory: true)
            .URLByAppendingPathComponent(managedObjectModelName.stringByAppendingPathExtension("sqlite")!, isDirectory: false)
        
        return url
    }
    
    private static func inferredPersistentStoreURLForApplicationGroupIdentifier(applicationGroupIdentifier: String) -> NSURL? {
        guard
            let containerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(applicationGroupIdentifier),
            let bundleIdentifier = NSBundle.mainBundle().bundleIdentifier,
            let managedObjectModelName = DataContextOptions.inferredManagedObjectModelName()
        else {
            return nil
        }
        
        let url = containerURL
            .URLByAppendingPathComponent("Library", isDirectory: true)
            .URLByAppendingPathComponent("Application Support", isDirectory: true)
            .URLByAppendingPathComponent(bundleIdentifier, isDirectory: true)
            .URLByAppendingPathComponent("CoreData", isDirectory: true)
            .URLByAppendingPathComponent(managedObjectModelName.stringByAppendingPathExtension("sqlite")!, isDirectory: false)
        
        return url
    }
    
}

