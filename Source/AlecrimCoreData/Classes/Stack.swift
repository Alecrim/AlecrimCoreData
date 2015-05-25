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
    
    internal let rootManagedObjectContext: NSManagedObjectContext!
    internal let mainManagedObjectContext: NSManagedObjectContext!
    internal lazy var backgroundManagedObjectContext: NSManagedObjectContext = { self.createBackgroundManagedObjectContext() }()
    
    // MARK: - constructors
    
    internal init?(contextOptions: ContextOptions) {
        self.contextOptions = contextOptions

        if contextOptions.managedObjectModel == nil {
            self.coordinator = nil
            self.store = nil
            self.rootManagedObjectContext = nil
            self.mainManagedObjectContext = nil

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
            self.rootManagedObjectContext = nil
            self.mainManagedObjectContext = nil
            
            return nil
        }
        
        // root (saving) managed object context
        let rmoc = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        rmoc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        rmoc.persistentStoreCoordinator = self.coordinator
        rmoc.undoManager = nil

        self.rootManagedObjectContext = rmoc
        
        // main thread managed object context
        let mmoc = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        mmoc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        mmoc.parentContext = self.rootManagedObjectContext
        
        self.mainManagedObjectContext = mmoc
        
        //
        self.addObservers()
    }
    
    internal init?(rootManagedObjectContext: NSManagedObjectContext, mainManagedObjectContext: NSManagedObjectContext, contextOptions: ContextOptions) {
        self.contextOptions = contextOptions
        self.coordinator = rootManagedObjectContext.persistentStoreCoordinator
        self.store = self.coordinator.persistentStores.first as! NSPersistentStore
        self.rootManagedObjectContext = rootManagedObjectContext
        self.mainManagedObjectContext = mainManagedObjectContext
        
        self.addObservers()
    }
    
    deinit {
        self.removeObservers()
    }
    
    private func addObservers() {
        if self.contextOptions.stackType == .SQLite && self.contextOptions.ubiquityEnabled {
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: Selector("persistentStoreCoordinatorStoresWillChange:"),
                name: NSPersistentStoreCoordinatorStoresWillChangeNotification,
                object: self.coordinator
            )
            
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: Selector("persistentStoreCoordinatorStoresDidChange:"),
                name: NSPersistentStoreCoordinatorStoresDidChangeNotification,
                object: self.coordinator
            )
            
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: Selector("persistentStoreDidImportUbiquitousContentChanges:"),
                name: NSPersistentStoreDidImportUbiquitousContentChangesNotification,
                object: self.coordinator
            )
        }
    }
    
    private func removeObservers() {
        if self.contextOptions.stackType == .SQLite && self.contextOptions.ubiquityEnabled {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.coordinator)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: self.coordinator)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: coordinator)
        }
    }

}

// MARK: - internal methods

extension Stack {

    internal func createBackgroundManagedObjectContext() -> NSManagedObjectContext {
        let backgroundContext = StackBackgroundManagedObjectContext(stack: self)
        
        return backgroundContext
    }

    internal func saveManagedObjectContext(context: NSManagedObjectContext) -> (Bool, NSError?) {
        var currentContext: NSManagedObjectContext? = context
        
        var success = false
        var error: NSError? = nil
        
        while let c = currentContext {
            if c.hasChanges {
                c.performBlockAndWait {
                    success = c.save(&error)
                }
            }
            else {
                success = true
            }
            
            if (!success) {
                break
            }
            
            currentContext = currentContext?.parentContext
        }
        
        return (success, error)
    }
    
}

// MARK: - private notification handler methods

extension Stack {
    
    @objc private func persistentStoreCoordinatorStoresWillChange(notification: NSNotification) {
        var currentContext: NSManagedObjectContext? = self.mainManagedObjectContext
        
        while let c = currentContext {
            c.performBlockAndWait {
                var error: NSError? = nil
                c.save(&error)
                c.reset()
            }
            
            currentContext = currentContext?.parentContext
        }
    }
    
    @objc private func persistentStoreCoordinatorStoresDidChange(notification: NSNotification) {
        var currentContext: NSManagedObjectContext? = self.mainManagedObjectContext
        
        while let c = currentContext {
            c.performBlockAndWait {
                c.reset()
            }
            
            currentContext = currentContext?.parentContext
        }
    }
    
    @objc private func persistentStoreDidImportUbiquitousContentChanges(notification: NSNotification) {
        var currentContext: NSManagedObjectContext? = self.mainManagedObjectContext
        
        while let c = currentContext {
            c.performBlockAndWait {
                c.mergeChangesFromContextDidSaveNotification(notification)
            }
            
            currentContext = currentContext?.parentContext
        }
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
            println(error)
            return nil
        }
    }
    
    private class func persistentStoreForInMemoryStoreTypeWithCoordinator(coordinator: NSPersistentStoreCoordinator, contextOptions: ContextOptions) -> NSPersistentStore? {
        var error: NSError? = nil
        
        if let store = coordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: contextOptions.configuration, URL: nil, options: contextOptions.storeOptions, error: &error) {
            return store
        }
        else {
            println(error)
            return nil
        }
    }

}

// MARK: - private classes

private final class StackBackgroundManagedObjectContext: NSManagedObjectContext {
    
    private unowned let stack: Stack
    
    private init(stack: Stack) {
        self.stack = stack
        super.init(concurrencyType: .PrivateQueueConcurrencyType)
        
        self.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.undoManager = nil
        self.parentContext = self.stack.rootManagedObjectContext
        

        self.addObservers()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.removeObservers()
    }
    
    private func addObservers() {
        if self.stack.contextOptions.stackType == .SQLite && self.stack.contextOptions.ubiquityEnabled {
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: Selector("persistentStoreCoordinatorStoresWillChange:"),
                name: NSPersistentStoreCoordinatorStoresWillChangeNotification,
                object: self.stack.coordinator
            )
            
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: Selector("persistentStoreCoordinatorStoresDidChange:"),
                name: NSPersistentStoreCoordinatorStoresDidChangeNotification,
                object: self.stack.coordinator
            )
            
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: Selector("persistentStoreDidImportUbiquitousContentChanges:"),
                name: NSPersistentStoreDidImportUbiquitousContentChangesNotification,
                object: self.stack.coordinator
            )
        }

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("backgroundManagedObjectContextWillSave:"),
            name: NSManagedObjectContextWillSaveNotification,
            object: self
        )

        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: Selector("backgroundManagedObjectContextDidSave:"),
            name: NSManagedObjectContextDidSaveNotification,
            object: self
        )
    }
    
    private func removeObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextWillSaveNotification, object: self)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: self)

        if self.stack.contextOptions.stackType == .SQLite && self.stack.contextOptions.ubiquityEnabled {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.stack.coordinator)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: self.stack.coordinator)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: self.stack.coordinator)
        }
        
    }

    @objc private func backgroundManagedObjectContextWillSave(notification: NSNotification) {
        if let context = notification.object as? NSManagedObjectContext {
            if let insertedObjects = context.insertedObjects as? Set<NSManagedObject> {
                if insertedObjects.count > 0 {
                    var error: NSError? = nil
                    if !context.obtainPermanentIDsForObjects((insertedObjects as NSSet).allObjects, error: &error) {
                        println(error)
                    }
                }
            }
        }
    }

    @objc private func backgroundManagedObjectContextDidSave(notification: NSNotification) {
        if let mainContext = self.stack.mainManagedObjectContext {
            mainContext.performBlockAndWait {
                if let userInfo = notification.userInfo {
                    let dict = userInfo as NSDictionary
                    if let updatedObjects = dict[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
                        if updatedObjects.count > 0 {
                            for object in updatedObjects {
                                mainContext.objectWithID(object.objectID).willAccessValueForKey(nil) // ensure that a fault has been fired
                            }
                        }
                    }
                }
                
                mainContext.mergeChangesFromContextDidSaveNotification(notification)
            }
        }
    }
    
    @objc private func persistentStoreCoordinatorStoresWillChange(notification: NSNotification) {
        self.performBlockAndWait {
            var error: NSError? = nil
            self.save(&error)
            self.reset()
        }
    }
    
    @objc private func persistentStoreCoordinatorStoresDidChange(notification: NSNotification) {
        self.performBlockAndWait {
            self.reset()
        }
    }
    
    @objc private func persistentStoreDidImportUbiquitousContentChanges(notification: NSNotification) {
        self.performBlockAndWait {
            self.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
}

