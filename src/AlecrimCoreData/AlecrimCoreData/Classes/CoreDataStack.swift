//
//  CoreDataStack.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-24.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    let model: NSManagedObjectModel
    let coordinator: NSPersistentStoreCoordinator
    let store: NSPersistentStore
    
    let savingContext: NSManagedObjectContext
    let mainContext: NSManagedObjectContext
    
    // TODO: error handling
    init(modelName name: String?) {
        let bundle = NSBundle.mainBundle()
        let modelName = (name == nil ? bundle.infoDictionary[kCFBundleNameKey] as String : name!)
        let modelURL = bundle.URLForResource(modelName, withExtension: "momd")
        
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        let applicationSupportDirectoryURL = urls[urls.endIndex - 1] as NSURL

        let localStoreDirectoryURL = applicationSupportDirectoryURL.URLByAppendingPathComponent(bundle.bundleIdentifier, isDirectory: true)
        if !fileManager.fileExistsAtPath(localStoreDirectoryURL.absoluteString) {
            fileManager.createDirectoryAtURL(localStoreDirectoryURL, withIntermediateDirectories: true, attributes: nil, error: nil)
        }

        let storeFilename = modelName.stringByAppendingPathExtension("sqlite")
        let localStoreFileURL = localStoreDirectoryURL.URLByAppendingPathComponent(storeFilename, isDirectory: false)
        
        self.model = NSManagedObjectModel(contentsOfURL: modelURL)
        self.coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model)
        self.store = self.coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: localStoreFileURL, options: nil, error: nil)
        
        self.savingContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.savingContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.savingContext.persistentStoreCoordinator = self.coordinator
        
        self.mainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.mainContext.parentContext = self.savingContext
    }
    
//    deinit {
//        println("deinit - CoreDataStack")
//    }
    
}

extension CoreDataStack {
    
    func createBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundContext.parentContext = self.mainContext
        
        return backgroundContext
    }
    
}

extension CoreDataStack {

    func saveContext(context: NSManagedObjectContext) -> (Bool, NSError?) {
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
    
    func saveContext(context: NSManagedObjectContext, completion: ((Bool, NSError?) -> ())?) {
        context.performBlock { [unowned self] in
            var success = false
            var error: NSError? = nil
            
            success = context.save(&error)
            
            if success {
                if let parentContext = context.parentContext {
                    self.saveContext(parentContext, completion: completion)
                }
                else {
                    if let closure = completion {
                        closure(success, error)
                    }
                }
            }
            else {
                if let closure = completion {
                    closure(success, error)
                }
            }
        }
    }

}

