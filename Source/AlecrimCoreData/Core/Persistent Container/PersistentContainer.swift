//
//  PersistentContainer.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 11/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

@objc(ALCPersistentContainer)
open class PersistentContainer: BasePersistentContainer {
    
    // MARK: -
    
    public private(set) lazy var backgroundContext: ManagedObjectContext = self.newBackgroundContext()
    
    // MARK: -
    
    fileprivate var didImportUbiquitousContentNotificationObserver: NSObjectProtocol?

    
    // MARK: -
    
    /// Use caution when using this initializer.
    public convenience init(name: String? = nil) {
        try! self.init(name: name, managedObjectModel: type(of: self).managedObjectModel(), storageType: .disk, persistentStoreURL: try! type(of: self).persistentStoreURL(), persistentStoreDescriptionOptions: nil, ubiquitousConfiguration: nil)
    }
    
    public init(name: String? = nil, managedObjectModel: NSManagedObjectModel, storageType: PersistentContainerStorageType, persistentStoreURL: URL, persistentStoreDescriptionOptions: [String : NSObject]? = nil, ubiquitousConfiguration: PersistentContainerUbiquitousConfiguration? = nil) throws {
        //
        let name = name ?? persistentStoreURL.deletingPathExtension().lastPathComponent

        //
        if storageType == .disk {
            let directoryPath = persistentStoreURL.deletingLastPathComponent().path
            
            if !FileManager.default.fileExists(atPath: directoryPath) {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
            }
        }
        
        //
        let persistentStoreDescription = NSPersistentStoreDescription(url: persistentStoreURL)
        
        //
        persistentStoreDescription.type = (storageType == .disk ? NSSQLiteStoreType : NSInMemoryStoreType)
        persistentStoreDescription.shouldInferMappingModelAutomatically = true
        persistentStoreDescription.shouldMigrateStoreAutomatically = true
        
        // a chance for configuring options (such `NSPersistentHistoryTrackingKey`, for example)
        persistentStoreDescriptionOptions?.forEach {
            persistentStoreDescription.setOption($0.value, forKey: $0.key)
        }
        
        // deprecated ubiquitous support
        #if os(macOS) || os(iOS)
        if let ubiquitousConfiguration = ubiquitousConfiguration {
            persistentStoreDescription.setOption(ubiquitousConfiguration.containerIdentifier as NSString, forKey: NSPersistentStoreUbiquitousContainerIdentifierKey)
            persistentStoreDescription.setOption(ubiquitousConfiguration.contentRelativePath as NSString, forKey: NSPersistentStoreUbiquitousContentURLKey)
            persistentStoreDescription.setOption(ubiquitousConfiguration.contentName as NSString, forKey: NSPersistentStoreUbiquitousContentNameKey)
        }
        #endif
        
        //
        try super.init(name: name, managedObjectModel: managedObjectModel, persistentStoreDescription: persistentStoreDescription) { persistentContainer, _, error in
            guard error == nil else {
                return
            }
            
            //
            #if os(macOS) || os(iOS)
            if let _ = ubiquitousConfiguration {
                (persistentContainer as? PersistentContainer)?.didImportUbiquitousContentNotificationObserver = NotificationCenter.default.addObserver(forName: .NSPersistentStoreDidImportUbiquitousContentChanges, object: persistentContainer.persistentStoreCoordinator, queue: nil) { [weak persistentContainer] notification in
                    guard let context = persistentContainer?.viewContext.parent ?? persistentContainer?.viewContext else {
                        return
                    }
                    
                    context.performAndWait {
                        context.mergeChanges(fromContextDidSave: notification)
                    }
                }
            }
            #endif
        }
    }
    
    public override init(name: String, managedObjectModel: NSManagedObjectModel, persistentStoreDescription: NSPersistentStoreDescription, completionHandler: @escaping (NSPersistentContainer, NSPersistentStoreDescription, Error?) -> Void) throws {
        try super.init(name: name, managedObjectModel: managedObjectModel, persistentStoreDescription: persistentStoreDescription, completionHandler: completionHandler)
    }
    
    deinit {
        if let didImportUbiquitousContentNotificationObserver = self.didImportUbiquitousContentNotificationObserver {
            NotificationCenter.default.removeObserver(didImportUbiquitousContentNotificationObserver)
            self.didImportUbiquitousContentNotificationObserver = nil
        }
    }

}


// MARK: -

open class BasePersistentContainer: NSPersistentContainer {

    // MARK: -
    
    public init(name: String, managedObjectModel: NSManagedObjectModel, persistentStoreDescription: NSPersistentStoreDescription, completionHandler: @escaping (NSPersistentContainer, NSPersistentStoreDescription, Error?) -> Void) throws {
        //
        super.init(name: name, managedObjectModel: managedObjectModel)
        
        // we need to load synchronously in this implementation
        persistentStoreDescription.shouldAddStoreAsynchronously = false
        self.persistentStoreDescriptions = [persistentStoreDescription]
        
        //
        var outError: Swift.Error?
        
        self.loadPersistentStores { description, error in
            //
            if let error = error {
                outError = error
            }
            else {
                self.configureManagedObjectContext(self.viewContext)
            }
            
            //
            completionHandler(self, description, error)
        }
        
        if let outError = outError {
            throw outError
        }
    }
    
    // MARK: -
    
    open override func newBackgroundContext() -> NSManagedObjectContext {
        let context = super.newBackgroundContext()
        self.configureManagedObjectContext(context)
        
        return context
    }
    
    open override func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        super.performBackgroundTask { context in
            self.configureManagedObjectContext(context)
            block(context)
        }
    }
    
    // MARK: -
    
    open func configureManagedObjectContext(_ context: NSManagedObjectContext) {
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

}

