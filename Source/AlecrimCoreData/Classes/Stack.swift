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
  
    private let stackType: StackType;
    private let model: NSManagedObjectModel!
    
    private var coordinator: NSPersistentStoreCoordinator! {
        didSet {
            if self.coordinator != oldValue && self.stackType == .SQLite && Config.iCloudEnabled {
                if self.coordinator != nil {
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
                else {
                    NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresWillChangeNotification, object: self.coordinator)
                    NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreCoordinatorStoresDidChangeNotification, object: self.coordinator)
                    NSNotificationCenter.defaultCenter().removeObserver(self, name: NSPersistentStoreDidImportUbiquitousContentChangesNotification, object: coordinator)
                }
            }
        }
    }

    private let store: NSPersistentStore!
    
    private let rootManagedObjectContext: NSManagedObjectContext!
    internal let mainManagedObjectContext: NSManagedObjectContext!

    // MARK: - constructors
    
    internal init?(stackType: StackType, var managedObjectModelName: String?, storeOptions: [NSObject : AnyObject]?) {
        self.stackType = stackType

        // if managed object model name is nil, try to get default name from main bundle
        let mainBundle = Config.mainBundle
        let modelBundle = Config.modelBundle
        
        if managedObjectModelName == nil {
            if let infoDictionary = mainBundle.infoDictionary {
                managedObjectModelName = infoDictionary[kCFBundleNameKey] as? String
            }
        }
        
        if managedObjectModelName == nil {
            // Swift 1.2 things
            self.model = nil
            self.coordinator = nil
            self.store = nil
            self.rootManagedObjectContext = nil
            self.mainManagedObjectContext = nil

            //
            return nil
        }
        
        // model
        self.model = Stack.managedObjectModelWithName(managedObjectModelName, bundle: modelBundle)
        
        if self.model == nil {
            // Swift 1.2 things
            self.coordinator = nil
            self.store = nil
            self.rootManagedObjectContext = nil
            self.mainManagedObjectContext = nil
            
            //
            return nil
        }
        
        // coordinator
        self.coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model)
        
        // store
        switch self.stackType {
        case .SQLite:
            self.store = Stack.persistentStoreForSQLiteStoreTypeWithCoordinator(self.coordinator, managedObjectModelName: managedObjectModelName, mainBundle: mainBundle, storeOptions: storeOptions)
            
        case .InMemory:
            self.store = Stack.persistentStoreForInMemoryStoreTypeWithCoordinator(self.coordinator, storeOptions: storeOptions)
        }
        
        if self.store == nil {
            // Swift 1.2 things
            self.rootManagedObjectContext = nil
            self.mainManagedObjectContext = nil
            
            //
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
    }
    
    deinit {
        self.coordinator = nil // setting coordinator to nil also removes notifications
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
    
    private class func persistentStoreForSQLiteStoreTypeWithCoordinator(coordinator: NSPersistentStoreCoordinator, managedObjectModelName: String?, mainBundle: NSBundle, var storeOptions: [NSObject : AnyObject]?) -> NSPersistentStore? {
        if let momn = managedObjectModelName {
            if let localStoreURL = Stack.localSQLiteStoreURLForBundle(mainBundle) {
                if let localStorePath = localStoreURL.path {
                    let fileManager = NSFileManager.defaultManager()
                    var error: NSError? = nil
                    
                    if !fileManager.fileExistsAtPath(localStorePath) {
                        if !fileManager.createDirectoryAtURL(localStoreURL, withIntermediateDirectories: true, attributes: nil, error: &error) {
                            println(error)
                            return nil
                        }
                    }
                }
                
                let storeFilename = momn.stringByAppendingPathExtension("sqlite")!
                let localStoreFileURL = localStoreURL.URLByAppendingPathComponent(storeFilename, isDirectory: false)
                
                if storeOptions == nil {
                    storeOptions = [NSObject : AnyObject]()
                    if Config.iCloudEnabled {
                        storeOptions?[NSPersistentStoreUbiquitousContentNameKey] = Config.ubiquitousContentName
                        storeOptions?[NSPersistentStoreUbiquitousContentURLKey] = Config.ubiquitousContentURL
                        storeOptions?[NSMigratePersistentStoresAutomaticallyOption] = true // always true, ignores Config value
                        storeOptions?[NSInferMappingModelAutomaticallyOption] = true // always true, ignores Config value
                    }
                    else {
                        storeOptions?[NSMigratePersistentStoresAutomaticallyOption] = Config.migratePersistentStoresAutomatically
                        storeOptions?[NSInferMappingModelAutomaticallyOption] = Config.inferMappingModelAutomaticallyOption
                    }
                }
                
                var error: NSError? = nil
                if let store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: localStoreFileURL, options: storeOptions, error: &error) {
                    return store
                }
                else {
                    println(error)
                    return nil
                }
            }
        }
        
        return nil
    }
    
    private class func persistentStoreForInMemoryStoreTypeWithCoordinator(coordinator: NSPersistentStoreCoordinator, storeOptions: [NSObject : AnyObject]?) -> NSPersistentStore? {
        var error: NSError? = nil
        
        if let store = coordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: storeOptions, error: &error) {
            return store
        }
        else {
            println(error)
            return nil
        }
    }

    private class func localSQLiteStoreURLForBundle(bundle: NSBundle) -> NSURL? {
        if let bundleIdentifier = bundle.bundleIdentifier {
            let fileManager = NSFileManager.defaultManager()
            let urls = fileManager.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)

            if let applicationSupportDirectoryURL = urls.last as? NSURL {
                return applicationSupportDirectoryURL.URLByAppendingPathComponent(bundleIdentifier, isDirectory: true)
            }
        }
        
        return nil
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

