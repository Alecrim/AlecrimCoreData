//
//  DataContext.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014, 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public class DataContext: NSManagedObjectContext {
    
    private var observers = [NSObjectProtocol]()

    private var rootSavingDataContext: RootSavingDataContext? {
        var context: NSManagedObjectContext = self
        
        while context.parentContext != nil {
            context = context.parentContext!
        }
        
        return context as? RootSavingDataContext
    }
    
    public override var parentContext: NSManagedObjectContext? {
        willSet {
            if let oldValue = self.parentContext as? RootSavingDataContext {
                oldValue.childDataContextHashTable.removeObject(self)
            }
        }
        didSet {
            if let newValue = self.parentContext as? RootSavingDataContext {
                newValue.childDataContextHashTable.addObject(self)
            }
        }
    }

    // any context
    
    public override init(concurrencyType: NSManagedObjectContextConcurrencyType) {
        super.init(concurrencyType: concurrencyType)
        self.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        self.addObservers()
    }
    
    deinit {
        self.removeObservers()
    }
    
    // main thread context
    
    public convenience init() {
        self.init(dataContextOptions: DataContextOptions())
    }
    
    public convenience init(dataContextOptions: DataContextOptions) {
        self.init(concurrencyType: .MainQueueConcurrencyType)
        
        self.name = "Main Thread Context"
        self.parentContext = try! RootSavingDataContext(rootSavingDataContextOptions: dataContextOptions)
    }
    
    // background context
    
    public convenience init(parentContext: NSManagedObjectContext) {
        self.init(concurrencyType: .PrivateQueueConcurrencyType)
        
        if let parentDataContext = parentContext as? DataContext, let rootSavingDataContext = parentDataContext.rootSavingDataContext {
            self.name = "Background Context " + String(rootSavingDataContext.childDataContexts.count)
            self.parentContext = rootSavingDataContext
        }
        else {
            self.parentContext = parentContext
        }
        
        self.undoManager = nil
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func save() throws {
        guard self.hasChanges else { return }
        
        self.rootSavingDataContext?.savedChildContext = self
        try super.save()
        
        if let parentContext = self.parentContext {
            var error: ErrorType? = nil
            
            parentContext.performBlockAndWait {
                do {
                    try parentContext.save()
                }
                catch let innerError {
                    error = innerError
                }
            }
            
            if let error = error {
                throw error
            }
        }
    }
    
    public func perform(closure: () -> Void) {
        self.performBlock(closure)
    }
    
    public func performAndWait(closure: () -> Void) {
        self.performBlockAndWait(closure)
    }
    
    private func addObservers() {
        // this context will save
        self.addObserverForName(NSManagedObjectContextWillSaveNotification) { notification in
            guard let notificationContext = notification.object as? NSManagedObjectContext where !notificationContext.insertedObjects.isEmpty else { return }
            
            do {
                try notificationContext.obtainPermanentIDsForObjects(Array(notificationContext.insertedObjects))
            }
            catch {
                
            }
        }
    }
    
    private func removeObservers() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        for observer in self.observers {
            notificationCenter.removeObserver(observer)
        }
    }
    
    private func addObserverForName(name: String, closure: (NSNotification) -> Void) {
        let observer = NSNotificationCenter.defaultCenter().addObserverForName(name, object: self, queue: nil, usingBlock: closure)
        self.observers.append(observer)
    }
    
}

private class RootSavingDataContext: DataContext {
    
    private static let genericError = NSError(domain: "com.alecrim.AlecrimCoreData", code: NSCoreDataError, userInfo: nil)
    private static let savedChildContextUserInfoKey = "com.alecrim.AlecrimCoreData.DataContext.SavedChildContext"
    
    private let rootSavingDataContextOptions: DataContextOptions

    private let childDataContextHashTable = NSHashTable.weakObjectsHashTable()
    private var childDataContexts: [NSManagedObjectContext] { return self.childDataContextHashTable.allObjects as! [DataContext] }
    
    private var savedChildContext: NSManagedObjectContext? {
        get {
            return self.userInfo[RootSavingDataContext.savedChildContextUserInfoKey] as? NSManagedObjectContext
        }
        set {
            if newValue == nil {
                self.userInfo.removeObjectForKey(RootSavingDataContext.savedChildContextUserInfoKey)
            }
            else if self.savedChildContext == nil { // do not assign if previous value is not nil
                self.userInfo[RootSavingDataContext.savedChildContextUserInfoKey] = newValue
            }
        }
    }
 
    private init(rootSavingDataContextOptions: DataContextOptions) throws {
        self.rootSavingDataContextOptions = rootSavingDataContextOptions
        super.init(concurrencyType: .PrivateQueueConcurrencyType)

        self.name = "Root Saving Context"
        self.undoManager = nil
        
        // only the root data context has a direct assigned persistent store coordinator
        try self.assignPersistentStoreCoordinator()
    }

    private required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private override func addObservers() {
        super.addObservers()
        
        // the root data context did save
        self.addObserverForName(NSManagedObjectContextDidSaveNotification) { notification in
            guard
                let notificationRootSavingDataContext = notification.object as? RootSavingDataContext where notificationRootSavingDataContext.childDataContexts.count > 0,
                let changeNotificationData = notification.userInfo
            else {
                return
            }
            
            var excludedChildContextFromMerge: NSManagedObjectContext? = nil
            if let savedChildContext = notificationRootSavingDataContext.savedChildContext {
                excludedChildContextFromMerge = savedChildContext
                notificationRootSavingDataContext.savedChildContext = nil
            }
            
            let contextsToMerge = notificationRootSavingDataContext.childDataContexts.filter({ $0 != excludedChildContextFromMerge })
            let updatedObjects = changeNotificationData[NSUpdatedObjectsKey] as? Set<NSManagedObject>
            
            for contextToMerge in contextsToMerge {
                contextToMerge.performBlock {
                    if let updatedObjects = updatedObjects where !updatedObjects.isEmpty {
                        for objectObject in updatedObjects {
                            contextToMerge.objectWithID(objectObject.objectID).willAccessValueForKey(nil) // ensures that a fault has been fired
                        }
                    }
                    
                    contextToMerge.mergeChangesFromContextDidSaveNotification(notification)
                }
            }
        }
    }
    
    private func assignPersistentStoreCoordinator() throws {
        // managed object model
        guard
            let managedObjectModelURL = self.rootSavingDataContextOptions.managedObjectModelURL,
            let managedObjectModel = NSManagedObjectModel(contentsOfURL: managedObjectModelURL)
        else {
            throw RootSavingDataContext.genericError
        }
        
        // persistent store coordinator
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        // persistent store
        switch self.rootSavingDataContextOptions.storeType {
        case .SQLite:
            guard
                let persistentStoreURL = self.rootSavingDataContextOptions.persistentStoreURL,
                let containerURL = persistentStoreURL.URLByDeletingLastPathComponent
            else {
                throw RootSavingDataContext.genericError
            }
            
            // if the directory does not exist, it will be created
            try NSFileManager.defaultManager().createDirectoryAtURL(containerURL, withIntermediateDirectories: true, attributes: nil)

            do {
                try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: self.rootSavingDataContextOptions.configuration, URL: persistentStoreURL, options: self.rootSavingDataContextOptions.options)
            }
            catch let error as NSError {
                var handled = false
                
                if error.domain == NSCocoaErrorDomain {
                    let migrationErrorCodes = [NSPersistentStoreIncompatibleVersionHashError, NSMigrationMissingSourceModelError, NSMigrationError]

                    if migrationErrorCodes.contains(error.code) {
                        handled = self.handleMigrationError(error)
                    }
                }
                
                if !handled {
                    throw error
                }
            }
            
        case .InMemory:
            try persistentStoreCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: self.rootSavingDataContextOptions.configuration, URL: nil, options: self.rootSavingDataContextOptions.options)
        }
        
        //
        self.persistentStoreCoordinator = persistentStoreCoordinator
    }
    
    private func handleMigrationError(error: NSError) -> Bool {
        return false
    }
    
}

