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
    
    // MARK: - options valid for all instances
    
    public static var defaultBatchSize: Int = 20
    public static var defaultComparisonPredicateOptions: NSComparisonPredicateOptions = [.CaseInsensitivePredicateOption, .DiacriticInsensitivePredicateOption]

    @available(*, unavailable, renamed="defaultBatchSize")
    public static var batchSize: Int = 20
    
    @available(*, unavailable, renamed="defaultComparisonPredicateOptions")
    public static var stringComparisonPredicateOptions: NSComparisonPredicateOptions = [.CaseInsensitivePredicateOption, .DiacriticInsensitivePredicateOption]

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
        let mainBundle = NSBundle.mainBundle()
        
        self.managedObjectModelURL = managedObjectModelURL
        self.persistentStoreURL = mainBundle.defaultPersistentStoreURL()
    }
    
    public init(persistentStoreURL: NSURL) {
        let mainBundle = NSBundle.mainBundle()
        
        self.managedObjectModelURL = mainBundle.defaultManagedObjectModelURL()
        self.persistentStoreURL = persistentStoreURL
    }
    
    public init() {
        let mainBundle = NSBundle.mainBundle()
        
        self.managedObjectModelURL = mainBundle.defaultManagedObjectModelURL()
        self.persistentStoreURL = mainBundle.defaultPersistentStoreURL()
    }
    
    // MARK: -

    public init(managedObjectModelBundle: NSBundle, managedObjectModelName: String, bundleIdentifier: String) {
        self.managedObjectModelURL = managedObjectModelBundle.managedObjectModelURLForManagedObjectModelName(managedObjectModelName)
        self.persistentStoreURL = managedObjectModelBundle.persistentStoreURLForManagedObjectModelName(managedObjectModelName, bundleIdentifier: bundleIdentifier)
    }
    
    /// Initializes ContextOptions with properties filled for use by main app and its extensions.
    ///
    /// - parameter managedObjectModelBundle:   The managed object model bundle. You can use `NSBundle(forClass: MyModule.MyDataContext.self)`, for example.
    /// - parameter managedObjectModelName:     The managed object model name without the extension. Example: `"MyGreatApp"`.
    /// - parameter bundleIdentifier:           The bundle identifier for use when creating the directory for the persisent store. Example: `"com.mycompany.MyGreatApp"`.
    /// - parameter applicationGroupIdentifier: The application group identifier (see Xcode target settings). Example: `"group.com.mycompany.MyGreatApp"` for iOS or `"12ABCD3EF4.com.mycompany.MyGreatApp"` for OS X where `12ABCD3EF4` is your team identifier.
    ///
    /// - returns: An initialized ContextOptions with properties filled for use by main app and its extensions.
    public init(managedObjectModelBundle: NSBundle, managedObjectModelName: String, bundleIdentifier: String, applicationGroupIdentifier: String) {
        self.managedObjectModelURL = managedObjectModelBundle.managedObjectModelURLForManagedObjectModelName(managedObjectModelName)
        self.persistentStoreURL = managedObjectModelBundle.persistentStoreURLForManagedObjectModelName(managedObjectModelName, bundleIdentifier: bundleIdentifier, applicationGroupIdentifier: applicationGroupIdentifier)
    }
    
}

// MARK: - Ubiquity (iCloud) helpers

extension DataContextOptions {
    
    #if os(OSX) || os(iOS)
    
    public var ubiquityEnabled: Bool {
        return self.storeType == .SQLite && self.options[NSPersistentStoreUbiquitousContainerIdentifierKey] != nil
    }
    
    public mutating func configureUbiquityWithContainerIdentifier(containerIdentifier: String, contentRelativePath: String = "Data/TransactionLogs", contentName: String = "UbiquityStore") {
        self.options[NSPersistentStoreUbiquitousContainerIdentifierKey] = containerIdentifier
        self.options[NSPersistentStoreUbiquitousContentURLKey] = contentRelativePath
        self.options[NSPersistentStoreUbiquitousContentNameKey] = contentName
        
        self.options[NSMigratePersistentStoresAutomaticallyOption] = true
        self.options[NSInferMappingModelAutomaticallyOption] = true
    }
 
    #endif
}


// MARK: - private NSBundle extensions

extension NSBundle {
    
    private var bundleName: String? {
        return self.infoDictionary?[String(kCFBundleNameKey)] as? String
    }
    
}

extension NSBundle {
    
    private func defaultManagedObjectModelURL() -> NSURL? {
        if let managedObjectModelName = self.bundleName {
            return self.managedObjectModelURLForManagedObjectModelName(managedObjectModelName)
        }
        
        return nil
    }
    
    private func defaultPersistentStoreURL() -> NSURL? {
        if let managedObjectModelName = self.bundleName, let bundleIdentifier = self.bundleIdentifier {
            return self.persistentStoreURLForManagedObjectModelName(managedObjectModelName, bundleIdentifier: bundleIdentifier)
        }
        
        return nil
    }
    
}

extension NSBundle {
    
    private func managedObjectModelURLForManagedObjectModelName(managedObjectModelName: String) -> NSURL? {
        return self.URLForResource(managedObjectModelName, withExtension: "momd")
    }
    
    private func persistentStoreURLForManagedObjectModelName(managedObjectModelName: String, bundleIdentifier: String) -> NSURL? {
        if let applicationSupportURL = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask).last {
            let url = applicationSupportURL
                .URLByAppendingPathComponent(bundleIdentifier, isDirectory: true)
                .URLByAppendingPathComponent("CoreData", isDirectory: true)
                .URLByAppendingPathComponent((managedObjectModelName as NSString).stringByAppendingPathExtension("sqlite")!, isDirectory: false)
            
            return url
        }
        
        return nil
    }
    
    private func persistentStoreURLForManagedObjectModelName(managedObjectModelName: String, bundleIdentifier: String, applicationGroupIdentifier: String) -> NSURL? {
        if let containerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(applicationGroupIdentifier) {
            let url = containerURL
                .URLByAppendingPathComponent("Library", isDirectory: true)
                .URLByAppendingPathComponent("Application Support", isDirectory: true)
                .URLByAppendingPathComponent(bundleIdentifier, isDirectory: true)
                .URLByAppendingPathComponent("CoreData", isDirectory: true)
                .URLByAppendingPathComponent((managedObjectModelName as NSString).stringByAppendingPathExtension("sqlite")!, isDirectory: false)
            
            return url
        }
        
        return nil
    }
    
}

// MARK: -

@available(*, unavailable, renamed="DataContextOptions")
public struct ContextOptions {
    
}
