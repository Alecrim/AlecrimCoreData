//
//  Stack.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-24.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public enum StackType {
    case SQLite
    case InMemory
}

internal final class Stack {
  
    internal let contextOptions: ContextOptions
    private let coordinator: NSPersistentStoreCoordinator!
    private let store: NSPersistentStore!
    
    private var rootManagedObjectContext: NSManagedObjectContext!
    internal private(set) var mainManagedObjectContext: NSManagedObjectContext!
    internal lazy var backgroundManagedObjectContext: NSManagedObjectContext = { self.createBackgroundManagedObjectContext() }()
    
    // MARK: - constructors
    
    internal init?(contextOptions: ContextOptions) {
        self.contextOptions = contextOptions

        if contextOptions.managedObjectModel == nil {
            self.coordinator = nil
            self.store = nil

            return nil
        }
        
        // coordinator
        self.coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.contextOptions.managedObjectModel)
        
        // store
        switch contextOptions.stackType {
        case .SQLite:
            self.store = Stack.persistentStoreForSQLiteStoreTypeWithCoordinator(self.coordinator, contextOptions: contextOptions)
            
        case .InMemory:
            self.store = Stack.persistentStoreForInMemoryStoreTypeWithCoordinator(self.coordinator, contextOptions: contextOptions)
        }
        
        if self.store == nil {
            return nil
        }
        
        // root (saving) managed object context
        self.rootManagedObjectContext = ManagedObjectContext(stack: self, type: .Root)
        self.rootManagedObjectContext.persistentStoreCoordinator = self.coordinator
        
        // main thread managed object context
        self.mainManagedObjectContext = ManagedObjectContext(stack: self, type: .Main)
        self.mainManagedObjectContext.parentContext = self.rootManagedObjectContext
    }
    
    internal init?(rootManagedObjectContext: NSManagedObjectContext, mainManagedObjectContext: NSManagedObjectContext, contextOptions: ContextOptions) {
        self.contextOptions = contextOptions
        self.coordinator = rootManagedObjectContext.persistentStoreCoordinator
        self.store = self.coordinator.persistentStores.first as! NSPersistentStore
        self.rootManagedObjectContext = rootManagedObjectContext
        self.mainManagedObjectContext = mainManagedObjectContext
    }
    
}

// MARK: - internal methods

extension Stack {

    internal func createBackgroundManagedObjectContext() -> NSManagedObjectContext {
        let backgroundContext = ManagedObjectContext(stack: self, type: .Background)
        backgroundContext.parentContext = self.rootManagedObjectContext
        
        return backgroundContext
    }

    internal func saveManagedObjectContext(context: NSManagedObjectContext) -> (Bool, NSError?) {
        var success = false
        var error: NSError? = nil
        
        if context.hasChanges {
            var currentContext: NSManagedObjectContext? = context

            while let c = currentContext {
                c.performBlockAndWait {
                    success = c.save(&error)
                }
                
                if (!success) {
                    break
                }
                
                currentContext = currentContext?.parentContext
            }
        }
        else {
            success = true // context does not have changes
        }
        
        return (success, error)
    }
    
}

// MARK: - private class methods

extension Stack {
    
    private class func managedObjectModelWithName(var name: String?, bundle: NSBundle) -> NSManagedObjectModel? {
        if let managedObjectModelName = name {
            if let managedObjectModelURL = bundle.URLForResource(managedObjectModelName, withExtension: "momd") {
                if let managedObjectModel = NSManagedObjectModel(contentsOfURL: managedObjectModelURL) {
                    return managedObjectModel
                }
            }
        }
        
        return nil
    }
    
    private class func persistentStoreForSQLiteStoreTypeWithCoordinator(coordinator: NSPersistentStoreCoordinator, contextOptions: ContextOptions) -> NSPersistentStore? {
        if contextOptions.ubiquityEnabled {
            contextOptions.storeOptions[NSPersistentStoreUbiquitousContentNameKey] = contextOptions.ubiquitousContentName
            contextOptions.storeOptions[NSPersistentStoreUbiquitousContentURLKey] = contextOptions.ubiquitousContentURL
            contextOptions.storeOptions[NSPersistentStoreUbiquitousContainerIdentifierKey] = contextOptions.ubiquitousContainerIdentifier
            
            contextOptions.migratePersistentStoresAutomatically = true // always true, ignores previous value
            contextOptions.inferMappingModelAutomaticallyOption = true // always true, ignores previous value
        }

        contextOptions.storeOptions[NSMigratePersistentStoresAutomaticallyOption] = contextOptions.migratePersistentStoresAutomatically
        contextOptions.storeOptions[NSInferMappingModelAutomaticallyOption] = contextOptions.inferMappingModelAutomaticallyOption
        
        var error: NSError? = nil
        if let store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: contextOptions.configuration, URL: contextOptions.persistentStoreURL, options: contextOptions.storeOptions, error: &error) {
            return store
        }
        else {
            alecrimCoreDataHandleError(error)
            return nil
        }
    }
    
    private class func persistentStoreForInMemoryStoreTypeWithCoordinator(coordinator: NSPersistentStoreCoordinator, contextOptions: ContextOptions) -> NSPersistentStore? {
        var error: NSError? = nil
        
        if let store = coordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: contextOptions.configuration, URL: nil, options: contextOptions.storeOptions, error: &error) {
            return store
        }
        else {
            alecrimCoreDataHandleError(error)
            return nil
        }
    }

}

// MARK: - private classes

private enum ManagedObjectContextType {
    case Root
    case Main
    case Background
}

private final class ManagedObjectContext: NSManagedObjectContext {
    
    private unowned let stack: Stack
    private let type: ManagedObjectContextType
    
    private init(stack: Stack, type: ManagedObjectContextType) {
        self.stack = stack
        self.type = type
        
        let concurrencyType: NSManagedObjectContextConcurrencyType
        switch self.type {
        case .Main:
            concurrencyType = .MainQueueConcurrencyType
        default:
            concurrencyType = .PrivateQueueConcurrencyType
        }
        
        super.init(concurrencyType: concurrencyType)
        
        self.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        if type != .Main {
            self.undoManager = nil
        }

        self.addObservers()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.removeObservers()
    }
    
    private func addObservers() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        if self.stack.contextOptions.stackType == .SQLite && self.stack.contextOptions.ubiquityEnabled {
            notificationCenter.addObserver(self, selector: Selector("persistentStoreCoordinatorStoresWillChange:"), name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.stack.coordinator)
            notificationCenter.addObserver(self, selector: Selector("persistentStoreCoordinatorStoresDidChange:"), name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: self.stack.coordinator)
            notificationCenter.addObserver(self, selector: Selector("persistentStoreDidImportUbiquitousContentChanges:"), name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: self.stack.coordinator)
        }

        notificationCenter.addObserver(self, selector: Selector("managedObjectContextWillSave:"), name: NSManagedObjectContextWillSaveNotification, object: self)
        
        if self.type != .Root {
            notificationCenter.addObserver(self, selector: Selector("rootManagedObjectContextDidSave:"), name: NSManagedObjectContextDidSaveNotification, object: self.stack.rootManagedObjectContext)
        }
    }
    
    private func removeObservers() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        notificationCenter.removeObserver(self, name: NSManagedObjectContextWillSaveNotification, object: self)
        
        if self.type != .Root {
            notificationCenter.removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: self.stack.rootManagedObjectContext)
        }

        if self.stack.contextOptions.stackType == .SQLite && self.stack.contextOptions.ubiquityEnabled {
            notificationCenter.removeObserver(self, name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.stack.coordinator)
            notificationCenter.removeObserver(self, name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: self.stack.coordinator)
            notificationCenter.removeObserver(self, name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: self.stack.coordinator)
        }
        
    }

    @objc private func managedObjectContextWillSave(notification: NSNotification) {
        if let context = notification.object as? NSManagedObjectContext, let insertedObjects = context.insertedObjects as? Set<NSManagedObject> where !insertedObjects.isEmpty {
            var error: NSError? = nil
            if !context.obtainPermanentIDsForObjects(Array(insertedObjects), error: &error) {
                alecrimCoreDataHandleError(error)
            }
        }
    }

    @objc private func rootManagedObjectContextDidSave(notification: NSNotification) {
        if self.type != .Root {
            ManagedObjectContext.mergeChangesFromContextDidSaveNotification(notification, intoContext: self)
        }
    }
    
    @objc private func persistentStoreCoordinatorStoresWillChange(notification: NSNotification) {
        self.performBlock {
            var error: NSError? = nil
            self.save(&error)
            if error != nil {
                alecrimCoreDataHandleError(error)
            }
            
            self.reset()
        }
    }
    
    @objc private func persistentStoreCoordinatorStoresDidChange(notification: NSNotification) {
        self.performBlock {
            self.reset()
        }
    }
    
    @objc private func persistentStoreDidImportUbiquitousContentChanges(notification: NSNotification) {
        ManagedObjectContext.mergeChangesFromContextDidSaveNotification(notification, intoContext: self)
    }
    
    private class func mergeChangesFromContextDidSaveNotification(notification: NSNotification, intoContext context: NSManagedObjectContext) {
        context.performBlock {
            if let userInfo = notification.userInfo {
                let dict = userInfo as NSDictionary
                if let updatedObjects = dict[NSUpdatedObjectsKey] as? Set<NSManagedObject> where !updatedObjects.isEmpty {
                    for objectObject in updatedObjects {
                        context.objectWithID(objectObject.objectID).willAccessValueForKey(nil) // ensures that a fault has been fired
                    }
                }
            }
            
            context.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
}

