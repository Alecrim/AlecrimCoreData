//
//  DataContext.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014, 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

/// A `NSManagedObjectContext` subclass with the expected default behaviors for use with **AlecrimCoreData** (**ACD**).
///
/// - important: This class can be subclassed or used as is. The preferred way to add `Table` properties to a `DataContext`,
///              however, is writing an extension for it or using the generated extensions by **ACDGen** utility app
///              when a data context class name is specified at the moment of source code files creation.
///
/// - note: Virtually all other **ACD** types (like `Table` or `Attribute`, for example) can be used with "vanilla"
///         `NSManagedObjectContext` instances too. If so, the framework user will have to write all the custom handling
///         for the managed object contexts (i.e., *stack*), losing the conveniences provided by this class but achieving
///         greater control and flexibility about the behaviors she/he wants while also keeping the functionality from other
///         **ACD** types.
///
/// - warning: Mixing `DataContext` and "vanilla" `NSManagedObjextContext` instances is possible but is strongly
///            discouraged. Most often it is preferable to proceed with one approach (using only `DataContext` instances)
///            or another (using only `NSManagedObjectContext` instances).
///
/// - seealso: `DataContextOptions`, `Table`, `FetchedResultsController`
public class DataContext: NSManagedObjectContext {
    
    // MARK: - private properties
    
    private var observers = [NSObjectProtocol]()

    private var rootSavingDataContext: RootSavingDataContext? {
        var context: NSManagedObjectContext = self
        
        while context.parentContext != nil {
            context = context.parentContext!
        }
        
        return context as? RootSavingDataContext
    }
    
    // MARK: - public overrided properties
    
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
    
    // MARK: - init and deinit

    // any context
    
    public override init(concurrencyType: NSManagedObjectContextConcurrencyType) {
        super.init(concurrencyType: concurrencyType)
        self.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        self.addObservers()
    }
    
    deinit {
        self.removeObservers()
    }
    
    // MARK: - convenience initializers
    
    // main thread context
    
    /// Initializes a main thread context with the default (inferred) options.
    ///
    /// - returns: An initialized main thread context with the default (inferred) options.
    ///
    /// - seealso: `DataContextOptions`
    public convenience init() {
        self.init(dataContextOptions: DataContextOptions())
    }
    
    /// Initializes a main thread context with the given options.
    ///
    /// - parameter dataContextOptions: The options that will be applied to the root context of the initialized context.
    ///
    /// - returns: An initialized main thread context with the given options.
    ///
    /// - seealso: `DataContextOptions`
    public convenience init(dataContextOptions: DataContextOptions) {
        self.init(concurrencyType: .MainQueueConcurrencyType)
        
        self.name = "Main Thread Context"
        self.parentContext = try! RootSavingDataContext(rootSavingDataContextOptions: dataContextOptions)
    }
    
    // background context
    
    /// Initializes a background context that has as parent the given context or the root context of the given context.
    ///
    /// - parameter parentContext: The parent or relative context.
    ///
    /// - returns: An initialized background context.
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
    
    // MARK: - public overrided methods
    
    /// Attempts to commit unsaved changes to registered entities (objects) to the receiver’s parent store.
    ///
    /// - discussion: Unlike the default behavior of `NSManagedObjectContext`, this method actually propagates
    ///               the changes to the parent context that will try to do the same until the root saving context is reached.
    ///               When and if the root saving context is reached the changes will be merged into its child contexts
    ///               with the exception of the context that originated the saving process.
    ///
    /// - note: If the context does not have changes this method does nothing.
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
    
    // MARK: - public convenience methods
    
    /// Asynchronously performs a given closure on the receiver’s queue.
    ///
    /// - parameter closure: The closure to perform.
    ///
    /// - note: Calling this method is the same as calling `performBlock:` method.
    /// - seealso: `performBlock:`
    public func perform(closure: () -> Void) {
        self.performBlock(closure)
    }
    
    /// Synchronously performs a given closure on the receiver’s queue.
    ///
    /// - parameter closure: The closure to perform
    ///
    /// - note: Calling this method is the same as calling `performBlockAndWait:` method.
    /// - seealso: `performBlockAndWait:`
    public func performAndWait(closure: () -> Void) {
        self.performBlockAndWait(closure)
    }

    // MARK: - private methods

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

/// The root saving context.
private class RootSavingDataContext: DataContext {
    
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
            throw AlecrimCoreDataError.InvalidManagedObjectModelURL
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
                throw AlecrimCoreDataError.InvalidPersistentStoreURL
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

