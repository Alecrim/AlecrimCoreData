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
open class PersistentContainer: NSPersistentContainer {
    
    // MARK: -
    
    private var didImportUbiquitousContentNotificationObserver: NSObjectProtocol?
    
    // MARK: -
    
    public convenience init() {
        try! self.init(storageType: .disk, managedObjectModel: type(of: self).managedObjectModel(), persistentStoreURL: type(of: self).persistentStoreURL(), ubiquitousConfiguration: nil)
    }
    
    public init(storageType: PersistentContainerStorageType, managedObjectModel: NSManagedObjectModel, persistentStoreURL: URL, persistentStoreDescriptionOptions: [String : NSObject]? = nil, ubiquitousConfiguration: PersistentContainerUbiquitousConfiguration? = nil) throws {
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

        //
        persistentStoreDescription.type = (storageType == .disk ? NSSQLiteStoreType : NSInMemoryStoreType)
        persistentStoreDescription.shouldAddStoreAsynchronously = false
        persistentStoreDescription.shouldInferMappingModelAutomatically = true
        persistentStoreDescription.shouldMigrateStoreAutomatically = true

        // a change for configuring options (such `NSPersistentHistoryTrackingKey`, for example)
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
                    
                    context.performAndWait {
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

    open override func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        super.performBackgroundTask { context in
            //
            context.automaticallyMergesChangesFromParent = true
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            //
            block(context)
        }
    }
}
