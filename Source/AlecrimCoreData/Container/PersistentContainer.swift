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

@objc(ALCPersistentContainer)
open class PersistentContainer: NSPersistentContainer {
    
    // MARK: -
    
    private var didImportUbiquitousContentObserver: NSObjectProtocol?
    
    // MARK: -
    
    public init(bundle: Bundle = Bundle.main, storageType: StorageType = .disk, name: String? = nil, managedObjectModel: NSManagedObjectModel? = nil, managedObjectModelURL: URL? = nil, persistentStoreURL: URL? = nil, ubiquitousContainerIdentifier: String? = nil, ubiquitousContentRelativePath: String? = nil, ubiquitousContentName: String? = nil) throws {
        //
        guard let name = name ?? bundle.bundleIdentifier else {
            throw PersistentContainerError.invalidName
        }
        
        //
        if let managedObjectModel = managedObjectModel {
            super.init(name: name, managedObjectModel: managedObjectModel)
        }
        else {
            guard let managedObjectModelURL = managedObjectModelURL ?? bundle.managedObjectModelURL(forManagedObjectModelName: name) else {
                throw PersistentContainerError.invalidManagedObjectModelURL
            }
            
            guard let managedObjectModel = managedObjectModel ?? NSManagedObjectModel(contentsOf: managedObjectModelURL) ?? NSManagedObjectModel.mergedModel(from: [bundle]) else {
                throw PersistentContainerError.managedObjectModelNotFound
            }
            
            //
            super.init(name: name, managedObjectModel: managedObjectModel)
        }

        //
        guard let persistentStoreURL = persistentStoreURL ?? bundle.persistentStoreURL(forManagedObjectModelName: name, defaultDirectoryURL: type(of: self).defaultDirectoryURL()) else {
            throw PersistentContainerError.invalidPersistentStoreURL
        }

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
        
        if let ubiquitousContainerIdentifier = ubiquitousContainerIdentifier {
            persistentStoreDescription.setOption((ubiquitousContainerIdentifier) as NSString, forKey: NSPersistentStoreUbiquitousContainerIdentifierKey)
            persistentStoreDescription.setOption((ubiquitousContentRelativePath ?? "Data/TransactionLogs") as NSString, forKey: NSPersistentStoreUbiquitousContentURLKey)
            persistentStoreDescription.setOption((ubiquitousContentName ?? "UbiquityStore") as NSString, forKey: NSPersistentStoreUbiquitousContentNameKey)
        }
        
        //
        self.persistentStoreDescriptions = [persistentStoreDescription]
        
        // this should run synchronously since shouldAddStoreAsynchronously is false
        var outError: Swift.Error?
        
        self.loadPersistentStores { description, error in
            if let error = error {
                outError = error
            }
            
            //
            if let _ = ubiquitousContainerIdentifier {
                self.didImportUbiquitousContentObserver = NotificationCenter.default.addObserver(forName: .NSPersistentStoreDidImportUbiquitousContentChanges, object: self.persistentStoreCoordinator, queue: nil) { [weak self] notification in
                    guard let context = self?.viewContext.parent ?? self?.viewContext else {
                        return
                    }
                    
                    context.perform {
                        context.mergeChanges(fromContextDidSave: notification)
                    }
                }
            }
            
            //
            self.viewContext.automaticallyMergesChangesFromParent = true
            self.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
        
        if let outError = outError {
            throw outError
        }
    }
    
    deinit {
        if let didImportUbiquitousContentObserver = self.didImportUbiquitousContentObserver {
            self.didImportUbiquitousContentObserver = nil
            NotificationCenter.default.removeObserver(didImportUbiquitousContentObserver)
        }
    }
    
    // MARK: -

    open override func newBackgroundContext() -> NSManagedObjectContext {
        let context = super.newBackgroundContext()

        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return context
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
    
    public func managedObjectModelURL(forManagedObjectModelName managedObjectModelName: String) -> URL? {
        let tempURL = self.url(forResource: managedObjectModelName, withExtension: "momd") ?? self.url(forResource: managedObjectModelName, withExtension: "mom")
        
        guard let url = tempURL else {
            return nil
        }
        
        return url
    }
    
    public func persistentStoreURL(forManagedObjectModelName managedObjectModelName: String, defaultDirectoryURL: URL) -> URL? {
        let url = defaultDirectoryURL
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent((managedObjectModelName as NSString).appendingPathExtension("sqlite")!, isDirectory: false)
        
        return url
    }
    
    public func persistentStoreURL(forManagedObjectModelName managedObjectModelName: String, applicationName: String) -> URL? {
        guard let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else {
            return nil
        }
        
        let url = applicationSupportURL
            .appendingPathComponent(applicationName, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent((managedObjectModelName as NSString).appendingPathExtension("sqlite")!, isDirectory: false)
        
        return url
    }
    
    public func persistentStoreURL(forManagedObjectModelName managedObjectModelName: String, bundleIdentifier: String) -> URL? {
        guard let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else {
            return nil
        }
        
        let url = applicationSupportURL
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent((managedObjectModelName as NSString).appendingPathExtension("sqlite")!, isDirectory: false)
        
        return url
    }
    
    public func persistentStoreURL(forManagedObjectModelName managedObjectModelName: String, bundleIdentifier: String, applicationGroupIdentifier: String) -> URL? {
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

