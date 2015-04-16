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

private var backgroundContexts = NSMutableArray()

internal final class Stack {
  
    private let contextOptions: ContextOptions
    
    private let coordinator: NSPersistentStoreCoordinator!
    private let store: NSPersistentStore!
    
    private let rootManagedObjectContext: NSManagedObjectContext!
    internal let mainManagedObjectContext: NSManagedObjectContext!

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
    
    deinit {
        self.removeObservers()
    }
    
    private func addObservers() {
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
        let backgroundContext = StackBackgroundManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundContext.undoManager = nil
        
        backgroundContext.parentContext = self.rootManagedObjectContext
        backgroundContext.mainContext = self.mainManagedObjectContext
        
        return backgroundContext
    }
    
    internal func saveManagedObjectContext(context: NSManagedObjectContext) -> (Bool, NSError?) {
        var currentContext: NSManagedObjectContext? = context
        
        var success = false
        var error: NSError? = nil
        
        while let c = currentContext {
            c.performBlockAndWait {
                success = c.save(&error)
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
            c.performBlock {
                var error: NSError? = nil
                c.save(&error)
                c.reset()
            }
            
            currentContext = currentContext?.parentContext
        }
        
        for backgroundContext in backgroundContexts {
            if let c = backgroundContext as? StackBackgroundManagedObjectContext {
                c.performBlock {
                    var error: NSError? = nil
                    c.save(&error)
                    c.reset()
                }
            }
        }
    }
    
    @objc private func persistentStoreCoordinatorStoresDidChange(notification: NSNotification) {
        var currentContext: NSManagedObjectContext? = self.mainManagedObjectContext
        
        while let c = currentContext {
            c.performBlock {
                c.reset()
            }
            
            currentContext = currentContext?.parentContext
        }
        
        for backgroundContext in backgroundContexts {
            if let c = backgroundContext as? StackBackgroundManagedObjectContext {
                c.performBlock {
                    c.reset()
                }
            }
        }
    }
    
    @objc private func persistentStoreDidImportUbiquitousContentChanges(notification: NSNotification) {
        var currentContext: NSManagedObjectContext? = self.mainManagedObjectContext
        
        while let c = currentContext {
            c.performBlock {
                c.mergeChangesFromContextDidSaveNotification(notification)
            }
            
            currentContext = currentContext?.parentContext
        }
        
        for backgroundContext in backgroundContexts {
            if let c = backgroundContext as? StackBackgroundManagedObjectContext {
                c.performBlock {
                    c.mergeChangesFromContextDidSaveNotification(notification)
                }
            }
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
        if contextOptions.storeOptions == nil {
            contextOptions.storeOptions = [NSObject : AnyObject]()
            
            if contextOptions.ubiquityEnabled {
                contextOptions.storeOptions?[NSPersistentStoreUbiquitousContentNameKey] = contextOptions.ubiquitousContentName
                contextOptions.storeOptions?[NSPersistentStoreUbiquitousContentURLKey] = contextOptions.ubiquitousContentRelativePath
                contextOptions.storeOptions?[NSMigratePersistentStoresAutomaticallyOption] = true // always true, ignores Config value
                contextOptions.storeOptions?[NSInferMappingModelAutomaticallyOption] = true // always true, ignores Config value
            }
            else {
                contextOptions.storeOptions?[NSMigratePersistentStoresAutomaticallyOption] = contextOptions.migratePersistentStoresAutomatically
                contextOptions.storeOptions?[NSInferMappingModelAutomaticallyOption] = contextOptions.inferMappingModelAutomaticallyOption
            }
        }
        
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
    
    private var mainContext: NSManagedObjectContext! {
        didSet {
            if self.mainContext != oldValue {
                if self.mainContext != nil {
                    backgroundContexts.addObject(self)
                    
                    NSNotificationCenter.defaultCenter().addObserver(
                        self,
                        selector: Selector("backgroundManagedObjectContextDidSave:"),
                        name: NSManagedObjectContextDidSaveNotification,
                        object: self
                    )
                }
                else {
                    NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: self)
                    
                    backgroundContexts.removeObject(self)
                }
            }
        }
    }
    
    deinit {
        self.mainContext = nil // setting mainContext to nil also removes notifications
    }
    
    @objc private func backgroundManagedObjectContextDidSave(notification: NSNotification) {
        self.mainContext.performBlock {
            self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
    
}

