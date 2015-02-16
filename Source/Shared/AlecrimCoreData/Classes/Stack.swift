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
  
    private let model: NSManagedObjectModel!
    private let coordinator: NSPersistentStoreCoordinator!
    private let store: NSPersistentStore!
    
    private let rootManagedObjectContext: NSManagedObjectContext!
    internal let mainManagedObjectContext: NSManagedObjectContext!

    // MARK: - constructors
    
    internal init?(var managedObjectModelName: String?, stackType: StackType) {
        // if managed object model name is nil, try to get default name from main bundle
        let bundle = NSBundle.mainBundle()
        
        if managedObjectModelName == nil {
            if let infoDictionary = bundle.infoDictionary {
                managedObjectModelName = infoDictionary[kCFBundleNameKey] as? String
            }
        }
        
        if managedObjectModelName == nil {
            return nil
        }
        
        // model
        self.model = Stack.managedObjectModelWithName(managedObjectModelName, bundle: bundle)
        
        if self.model == nil {
            return nil
        }
        
        // coordinator
        self.coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model)
        
        // store
        switch stackType {
        case .SQLite:
            self.store = Stack.persistentStoreForSQLiteStoreTypeWithCoordinator(self.coordinator, managedObjectModelName: managedObjectModelName, bundle: bundle)
            
        case .InMemory:
            self.store = Stack.persistentStoreForInMemoryStoreTypeWithCoordinator(self.coordinator)
        }
        
        if self.store == nil {
            return nil
        }
        
        // root (saving) managed object context
        self.rootManagedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.rootManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.rootManagedObjectContext.persistentStoreCoordinator = self.coordinator
        self.rootManagedObjectContext.undoManager = nil
        
        // main thread managed object context
        self.mainManagedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.mainManagedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.mainManagedObjectContext.parentContext = self.rootManagedObjectContext
    }
    
    // MARK: - internal methods
    
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

    // MARK: - private class methods
    
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
    
    private class func persistentStoreForSQLiteStoreTypeWithCoordinator(coordinator: NSPersistentStoreCoordinator, managedObjectModelName: String?, bundle: NSBundle) -> NSPersistentStore? {
        if let momn = managedObjectModelName {
            if let localStoreURL = Stack.localSQLiteStoreURLForBundle(bundle) {
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
                
                var error: NSError? = nil
                if let store = coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: localStoreFileURL, options: nil, error: &error) {
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
    
    private class func persistentStoreForInMemoryStoreTypeWithCoordinator(coordinator: NSPersistentStoreCoordinator) -> NSPersistentStore? {
        var error: NSError? = nil
        
        if let store = coordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil, error: &error) {
            return store
        }
        else {
            println(error)
            return nil
        }
    }

    private class func localSQLiteStoreURLForBundle(bundle: NSBundle) -> NSURL? {
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        let applicationSupportDirectoryURL = urls.last as NSURL
        
        if let bundleIdentifier = bundle.bundleIdentifier {
            return applicationSupportDirectoryURL.URLByAppendingPathComponent(bundleIdentifier, isDirectory: true)
        }
        
        return nil
    }

}

private class StackBackgroundManagedObjectContext: NSManagedObjectContext {
    
    private var mainContext: NSManagedObjectContext! {
        didSet {
            if self.mainContext != nil {
                NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("backgroundManagedObjectContextDidSave:"), name: NSManagedObjectContextDidSaveNotification, object: self)
            }
            else {
                NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: self)
            }
        }
    }
    
    deinit {
        self.mainContext = nil
    }
    
    @objc private func backgroundManagedObjectContextDidSave(notification: NSNotification) {
        self.mainContext.performBlock {
            self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
        }
    }
    
}

