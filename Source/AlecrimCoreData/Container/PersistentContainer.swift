//
//  PersistentContainer.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 11/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// MARK: -

open class PersistentContainer: NSPersistentContainer {
    
    // MARK: -
    
    fileprivate let enableUbiquity: Bool
    
    // MARK: -
    
    public init(bundle: Bundle = Bundle.main, storageType: StorageType = .disk, name: String? = nil, managedObjectModel: NSManagedObjectModel? = nil, managedObjectModelURL: URL? = nil, persistentStoreURL: URL? = nil, ubiquitousContainerIdentifier: String? = nil, ubiquitousContentRelativePath: String? = nil, ubiquitousContentName: String? = nil) throws {
        //
        guard let name = name ?? bundle.bundleIdentifier else {
            throw PersistentContainerError.invalidName
        }
        
        guard let managedObjectModelURL = managedObjectModelURL ?? bundle.managedObjectModelURL(forManagedObjectModelName: name) else {
            throw PersistentContainerError.invalidManagedObjectModelURL
        }
        
        guard let managedObjectModel = managedObjectModel ?? NSManagedObjectModel(contentsOf: managedObjectModelURL) ?? NSManagedObjectModel.mergedModel(from: [bundle]) else {
            throw PersistentContainerError.managedObjectModelNotFound
        }
        
        guard let persistentStoreURL = persistentStoreURL ?? bundle.persistentStoreURL(forManagedObjectModelName: name, applicationName: name) else {
            throw PersistentContainerError.invalidPersistentStoreURL
        }
        
        //
        self.enableUbiquity = (ubiquitousContainerIdentifier != nil)
        super.init(name: name, managedObjectModel: managedObjectModel)
        
        //
        if storageType == .disk {
            let directoryPath = persistentStoreURL.deletingLastPathComponent().path
            
            if !FileManager.default.fileExists(atPath: directoryPath) {
                try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
            }
        }
        
        //
        let persistentStoreDescription = NSPersistentStoreDescription(url: persistentStoreURL)
        
        persistentStoreDescription.type = (storageType == .disk ? NSSQLiteStoreType : NSInMemoryStoreType)
        persistentStoreDescription.shouldAddStoreAsynchronously = false
        persistentStoreDescription.shouldInferMappingModelAutomatically = true
        persistentStoreDescription.shouldMigrateStoreAutomatically = true
        
        if self.enableUbiquity {
            persistentStoreDescription.setOption((ubiquitousContainerIdentifier!) as NSString, forKey: NSPersistentStoreUbiquitousContainerIdentifierKey)
            persistentStoreDescription.setOption((ubiquitousContentRelativePath ?? "Data/TransactionLogs") as NSString, forKey: NSPersistentStoreUbiquitousContentURLKey)
            persistentStoreDescription.setOption((ubiquitousContentName ?? "UbiquityStore") as NSString, forKey: NSPersistentStoreUbiquitousContentNameKey)
        }
        
        //
        self.persistentStoreDescriptions = [persistentStoreDescription]
        
        //
        var outError: Swift.Error?
        
        self.loadPersistentStores { description, error in
            if let error = error {
                outError = error
                return
            }
            
            if self.enableUbiquity {
                NotificationCenter.default.addObserver(self, selector: #selector(type(of: self).persistentStoreDidImportUbiquitousContentChanges(notification:)), name: .NSPersistentStoreDidImportUbiquitousContentChanges, object: self.persistentStoreCoordinator)
            }
        }
        
        if let outError = outError {
            throw outError
        }
        
        //
        self.viewContext.automaticallyMergesChangesFromParent = true
        self.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    deinit {
        if self.enableUbiquity {
            NotificationCenter.default.removeObserver(self, name: .NSPersistentStoreDidImportUbiquitousContentChanges, object: self.persistentStoreCoordinator)
        }
    }
    
    // MARK: -

    open override func newBackgroundContext() -> NSManagedObjectContext {
        let context = super.newBackgroundContext()

        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return context
    }
    
    // MARK: -
    
    @objc private func persistentStoreDidImportUbiquitousContentChanges(notification: Notification) {
        let context = self.viewContext.parent ?? self.viewContext
        
        context.perform {
            context.mergeChanges(fromContextDidSave: notification)
        }
        
    }
    
}

// MARK: -

open class GenericPersistentContainer<Context: NSManagedObjectContext> {
    
    // MARK: -
    
    fileprivate final class HelperPersistentContainer<Context: NSManagedObjectContext>: PersistentContainer {
        
        fileprivate override lazy var viewContext: NSManagedObjectContext = {
            let context = Context(concurrencyType: .mainQueueConcurrencyType)
            
            context.persistentStoreCoordinator = self.persistentStoreCoordinator
            
            context.automaticallyMergesChangesFromParent = true
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            return context
        }()
        
        fileprivate override func newBackgroundContext() -> NSManagedObjectContext {
            let context = Context(concurrencyType: .privateQueueConcurrencyType)
            
            context.persistentStoreCoordinator = self.persistentStoreCoordinator
            
            context.automaticallyMergesChangesFromParent = true
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            return context
        }
        
    }

    
    // MARK: -
    
    fileprivate let rawValue: NSPersistentContainer

    // MARK: -
    
    public init(bundle: Bundle = Bundle.main, storageType: StorageType = .disk, name: String? = nil, managedObjectModel: NSManagedObjectModel? = nil, managedObjectModelURL: URL? = nil, persistentStoreURL: URL? = nil, ubiquitousContainerIdentifier: String? = nil, ubiquitousContentRelativePath: String? = nil, ubiquitousContentName: String? = nil) throws {
        self.rawValue = try HelperPersistentContainer(bundle: bundle, storageType: storageType, name: name, managedObjectModel: managedObjectModel, managedObjectModelURL: managedObjectModelURL, persistentStoreURL: persistentStoreURL, ubiquitousContainerIdentifier: ubiquitousContainerIdentifier, ubiquitousContentRelativePath: ubiquitousContentRelativePath, ubiquitousContentName: ubiquitousContentName)
    }

    // MARK: -

    public final var viewContext: Context {
        return unsafeDowncast(self.rawValue.viewContext, to: Context.self)
    }
    
    public final func newBackgroundContext() -> Context {
        return unsafeDowncast(self.rawValue.newBackgroundContext(), to: Context.self)

    }
    
    public final func performBackgroundTask(_ block: @escaping (Context) -> Void) {
        self.rawValue.performBackgroundTask { managedObjectContext in
            block(unsafeDowncast(managedObjectContext, to: Context.self))
        }
    }
    
}


// MARK: -

public enum StorageType {
    case disk
    case memory
}

// MARK: -

public enum PersistentContainerError: Swift.Error {
    case invalidName
    case invalidManagedObjectModelURL
    case managedObjectModelNotFound
    case invalidPersistentStoreURL
}


// MARK: -

extension Bundle {
    
    fileprivate func managedObjectModelURL(forManagedObjectModelName managedObjectModelName: String) -> URL? {
        let tempURL = self.url(forResource: managedObjectModelName, withExtension: "momd") ?? self.url(forResource: managedObjectModelName, withExtension: "mom")
        
        guard let url = tempURL else {
            return nil
        }
        
        return url
    }
    
    fileprivate func persistentStoreURL(forManagedObjectModelName managedObjectModelName: String, applicationName: String) -> URL? {
        guard let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else {
            return nil
        }
        
        let url = applicationSupportURL
            .appendingPathComponent(applicationName, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent((managedObjectModelName as NSString).appendingPathExtension("sqlite")!, isDirectory: false)
        
        return url
    }
    
    private func persistentStoreURL(forManagedObjectModelName managedObjectModelName: String, bundleIdentifier: String) -> URL? {
        guard let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else {
            return nil
        }
        
        let url = applicationSupportURL
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent((managedObjectModelName as NSString).appendingPathExtension("sqlite")!, isDirectory: false)
        
        return url
    }
    
    private func persistentStoreURL(forManagedObjectModelName managedObjectModelName: String, bundleIdentifier: String, applicationGroupIdentifier: String) -> URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: applicationGroupIdentifier) else {
            return nil
        }
        
        let url = containerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent((managedObjectModelName as NSString).appendingPathExtension("sqlite")!, isDirectory: false)
        
        return url
    }
    
}

