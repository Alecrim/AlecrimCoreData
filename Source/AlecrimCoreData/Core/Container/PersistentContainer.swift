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
    
    private var didImportUbiquitousContentNotificationObserver: NSObjectProtocol?
    
    // MARK: -
    
    public convenience init() {
        try! self.init(storageType: .disk, managedObjectModel: type(of: self).managedObjectModel(), persistentStoreURL: type(of: self).persistentStoreURL(), ubiquitousConfiguration: nil)
    }
    
    public init(storageType: PersistentContainerStorageType, managedObjectModel: NSManagedObjectModel, persistentStoreURL: URL, ubiquitousConfiguration: PersistentContainerUbiquitousConfiguration? = nil) throws {
        //
        let name = persistentStoreURL.deletingPathExtension().lastPathComponent
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
        
        #if os(macOS) || os(iOS)
        if let ubiquitousConfiguration = ubiquitousConfiguration {
            persistentStoreDescription.setOption(ubiquitousConfiguration.containerIdentifier as NSString, forKey: NSPersistentStoreUbiquitousContainerIdentifierKey)
            persistentStoreDescription.setOption(ubiquitousConfiguration.contentRelativePath as NSString, forKey: NSPersistentStoreUbiquitousContentURLKey)
            persistentStoreDescription.setOption(ubiquitousConfiguration.contentName as NSString, forKey: NSPersistentStoreUbiquitousContentNameKey)
        }
        #endif
        
        //
        self.persistentStoreDescriptions = [persistentStoreDescription]
        
        // this should run synchronously since shouldAddStoreAsynchronously is false
        var outError: Swift.Error?
        
        self.loadPersistentStores { description, error in
            if let error = error {
                outError = error
            }
            
            //
            #if os(macOS) || os(iOS)
            if let _ = ubiquitousConfiguration {
                self.didImportUbiquitousContentNotificationObserver = NotificationCenter.default.addObserver(forName: .NSPersistentStoreDidImportUbiquitousContentChanges, object: self.persistentStoreCoordinator, queue: nil) { [weak self] notification in
                    guard let context = self?.viewContext.parent ?? self?.viewContext else {
                        return
                    }
                    
                    context.perform {
                        context.mergeChanges(fromContextDidSave: notification)
                    }
                }
            }
            #endif
            
            //
            self.viewContext.automaticallyMergesChangesFromParent = true
            self.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
        
        if let outError = outError {
            throw outError
        }
    }
    
    deinit {
        if let didImportUbiquitousContentNotificationObserver = self.didImportUbiquitousContentNotificationObserver {
            self.didImportUbiquitousContentNotificationObserver = nil
            NotificationCenter.default.removeObserver(didImportUbiquitousContentNotificationObserver)
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

        private lazy var _viewContext: NSManagedObjectContext = {
            let context = Context(concurrencyType: .mainQueueConcurrencyType)
            
            context.persistentStoreCoordinator = self.persistentStoreCoordinator
            
            context.automaticallyMergesChangesFromParent = true
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            
            return context
        }()

        fileprivate override var viewContext: NSManagedObjectContext { return self._viewContext }
        
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

    public convenience init() {
        try! self.init(storageType: .disk, managedObjectModel: type(of: self).managedObjectModel(), persistentStoreURL: type(of: self).persistentStoreURL(), ubiquitousConfiguration: nil)
    }

    public init(storageType: PersistentContainerStorageType = .disk, managedObjectModel: NSManagedObjectModel, persistentStoreURL: URL, ubiquitousConfiguration: PersistentContainerUbiquitousConfiguration? = nil) throws {
        self.rawValue = try HelperPersistentContainer<Context>(storageType: storageType, managedObjectModel: managedObjectModel, persistentStoreURL: persistentStoreURL, ubiquitousConfiguration: ubiquitousConfiguration)
    }

    // MARK: -

    open var viewContext: Context {
        return unsafeDowncast(self.rawValue.viewContext, to: Context.self)
    }
    
    open func newBackgroundContext() -> Context {
        return unsafeDowncast(self.rawValue.newBackgroundContext(), to: Context.self)
    }
    
    open func performBackgroundTask(_ block: @escaping (Context) -> Void) {
        self.rawValue.performBackgroundTask { managedObjectContext in
            block(unsafeDowncast(managedObjectContext, to: Context.self))
        }
    }
    
}


// MARK: -

public enum PersistentContainerStorageType {
    case disk
    case memory
}


public struct PersistentContainerUbiquitousConfiguration {
    public let containerIdentifier: String
    public let contentRelativePath: String
    public let contentName: String
    
    public init(containerIdentifier: String, contentRelativePath: String = "Data/TransactionLogs", contentName: String = "UbiquityStore") {
        self.containerIdentifier = containerIdentifier
        self.contentRelativePath = contentRelativePath
        self.contentName = contentName
    }
    
}

public enum PersistentContainerError: Error {
    case invalidManagedObjectModelURL
    case invalidPersistentStoreURL
    case invalidGroupContainerURL
    case applicationSupportDirectoryNotFound
    case managedObjectModelNotFound
}


// MARK: -

public protocol PersistentContainerType: class {}

extension PersistentContainer: PersistentContainerType {}
extension GenericPersistentContainer: PersistentContainerType {}

extension PersistentContainerType {
    
    public static func managedObjectModel(withName name: String? = nil, in bundle: Bundle? = nil) throws -> NSManagedObjectModel {
        let bundle = bundle ?? Bundle(for: Self.self)
        let name = name ?? bundle.bundleURL.deletingPathExtension().lastPathComponent

        let managedObjectModelURL = try self.managedObjectModelURL(withName: name, in: bundle)
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: managedObjectModelURL) else {
            throw PersistentContainerError.managedObjectModelNotFound
        }

        return managedObjectModel
    }
    
    private static func managedObjectModelURL(withName name: String, in bundle: Bundle) throws -> URL {
        let resourceURL = bundle.url(forResource: name, withExtension: "momd") ?? bundle.url(forResource: name, withExtension: "mom")
        
        guard let managedObjectModelURL = resourceURL else {
            throw PersistentContainerError.invalidManagedObjectModelURL
        }
        
        return managedObjectModelURL
    }

}

extension PersistentContainerType {
    
    public static func persistentStoreURL(withName name: String? = nil, in bundle: Bundle? = nil) throws -> URL {
        guard let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else {
            throw PersistentContainerError.applicationSupportDirectoryNotFound
        }
        
        let bundle = bundle ?? Bundle.main
        let bundleLastPathComponent = bundle.bundleURL.deletingPathExtension().lastPathComponent
        let name = name ?? bundleLastPathComponent
        
        let persistentStoreURL = applicationSupportURL
            .appendingPathComponent(bundleLastPathComponent, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent(name, isDirectory: false)
            .appendingPathExtension("sqlite")
        
        return persistentStoreURL
    }
    
    public static func persistentStoreURL(withName name: String? = nil, forSecurityApplicationGroupIdentifier applicationGroupIdentifier: String, in bundle: Bundle? = nil) throws -> URL {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: applicationGroupIdentifier) else {
            throw PersistentContainerError.invalidGroupContainerURL
        }

        let bundle = bundle ?? Bundle.main
        let bundleLastPathComponent = bundle.bundleURL.deletingPathExtension().lastPathComponent
        let name = name ?? bundleLastPathComponent

        let persistentStoreURL = containerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(bundleLastPathComponent, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent(name, isDirectory: false)
            .appendingPathExtension("sqlite")

        return persistentStoreURL
    }
    
}
