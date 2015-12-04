//
//  DataContext.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014, 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

/// A `NSManagedObjectContext` subclass with the default behaviors for use in conjunction with other **AlecrimCoreData**
/// (**ACD**) framework types.
///
/// - important: This class can be subclassed or used as is. The preferred way to add `Table` properties to a `DataContext`,
///              however, is writing an extension for it or using the generated extensions by **ACDGen** utility app
///              when a data context class name is specified at the moment of source code files creation.
///
/// - note: Virtually all other **ACD** types (like `Table` or `Attribute`, for example) can be used with "vanilla"
///         `NSManagedObjectContext` instances too. If so, the framework user will have to write all the custom handling
///         for the managed object contexts (i.e., "stack"), losing the conveniences provided by this class but achieving
///         greater control and flexibility about the behaviors she/he wants while also keeping the functionality from other
///         **ACD** types.
///
/// - warning: Mixing `DataContext` and "vanilla" `NSManagedObjextContext` instances is possible but is strongly
///            discouraged. Most often it is preferable to proceed with one approach (using only `DataContext` instances)
///            or another (using only `NSManagedObjectContext` instances).
///
/// - seealso: `DataContextOptions`, `Table`, `FetchedResultsController`
public class DataContext: ChildDataContext {
    
    // MARK: - init and dealloc
    
    /// Initializes a main thread context with the default (inferred) options.
    ///
    /// - returns: An initialized main thread context with the default (inferred) options.
    ///
    /// - seealso: `DataContextOptions`
    public convenience init() {
        do {
            self.init(dataContextOptions: try DataContextOptions())
        }
        catch let error {
            AlecrimCoreDataError.handleError(error)
        }
    }
    
    /// Initializes a main thread context with the given options.
    ///
    /// - parameter dataContextOptions: The options that will be applied to the root context of the initialized context.
    ///
    /// - returns: An initialized main thread context with the given options.
    ///
    /// - seealso: `DataContextOptions`
    public init(dataContextOptions: DataContextOptions) {
        do {
            let rootSavingDataContext = try RootSavingDataContext(dataContextOptions: dataContextOptions)
            super.init(concurrencyType: .MainQueueConcurrencyType, rootSavingDataContext: rootSavingDataContext)
            
            if #available(OSXApplicationExtension 10.10, *) {
                self.name = "Main Thread Context"
            }
        }
        catch let error {
            AlecrimCoreDataError.handleError(error)
        }
    }
    
    /// Initializes a background context that has as parent the given context or the root context of the given context.
    ///
    /// - parameter parentDataContext: The parent or relative context.
    ///
    /// - returns: An initialized background context.
    public init(parentDataContext: DataContext) {
        super.init(concurrencyType: .PrivateQueueConcurrencyType, rootSavingDataContext: parentDataContext.rootSavingDataContext)
        
        if #available(OSXApplicationExtension 10.10, *) {
            self.name = "Background Context"
        }
        
        self.undoManager = nil
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

/// The root saving data context.
public class RootSavingDataContext: ManagedObjectContext {
    
    // MARK: - public properties
    
    /// The options applied to this data context.
    public let dataContextOptions: DataContextOptions
    
    // MARK: - init and deinit
    
    /// Initializes a root saving data context with the given options.
    ///
    /// - parameter dataContextOptions: The options that will be applied.
    ///
    /// - returns: An initialized root saving data context with the given options.
    ///
    /// - seealso: `DataContextOptions`
    public init(dataContextOptions: DataContextOptions) throws {
        self.dataContextOptions = dataContextOptions
        super.init(concurrencyType: .PrivateQueueConcurrencyType)
        
        if #available(OSXApplicationExtension 10.10, *) {
            self.name = "Root Saving Context"
        }
        
        self.undoManager = nil
        
        // only the root data context has a direct assigned persistent store coordinator
        try self.assignPersistentStoreCoordinator()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - private methods
    
    private func assignPersistentStoreCoordinator() throws {
        // managed object model
        guard
            let managedObjectModelURL = self.dataContextOptions.managedObjectModelURL,
            let managedObjectModel = NSManagedObjectModel(contentsOfURL: managedObjectModelURL)
        else {
            throw AlecrimCoreDataError.InvalidManagedObjectModelURL
        }
        
        // persistent store coordinator
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        // persistent store
        switch self.dataContextOptions.storeType {
        case .SQLite:
            guard
                let persistentStoreURL = self.dataContextOptions.persistentStoreURL,
                let containerURL = persistentStoreURL.URLByDeletingLastPathComponent
            else {
                throw AlecrimCoreDataError.InvalidPersistentStoreURL
            }
            
            // if the directory does not exist, it will be created
            try NSFileManager.defaultManager().createDirectoryAtURL(containerURL, withIntermediateDirectories: true, attributes: nil)
            
            do {
                try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: self.dataContextOptions.configuration, URL: persistentStoreURL, options: self.dataContextOptions.options)
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
            try persistentStoreCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: self.dataContextOptions.configuration, URL: nil, options: self.dataContextOptions.options)
        }
        
        //
        self.persistentStoreCoordinator = persistentStoreCoordinator
    }
    
    private func handleMigrationError(error: NSError) -> Bool {
        return false
    }
    
}

/// A data context that is child from a RootSavingDataContext instance.
public class ChildDataContext: ManagedObjectContext {
    
    // MARK: - private properties
    
    private var enableMergeFromRootSavingDataContext = true
    
    // MARK: - public properties
    
    /// The root saving data context (and parent context) of this context.
    public let rootSavingDataContext: RootSavingDataContext
    
    // MARK: - init and dealloc
    
    //// Initializes a child data context with a given concurrency type and parent root saving data context.
    ///
    /// - parameter concurrencyType:       The concurrency pattern with which context will be used.
    /// - parameter rootSavingDataContext: The root saving data context (and parent context) of this context.
    ///
    /// - returns: A child data context initialized to use the given concurrency type and parent root saving data context.
    public init(concurrencyType: NSManagedObjectContextConcurrencyType, rootSavingDataContext: RootSavingDataContext) {
        self.rootSavingDataContext = rootSavingDataContext
        super.init(concurrencyType: concurrencyType)
        
        self.parentContext = self.rootSavingDataContext
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - public overrided methods
    
    /// Attempts to commit unsaved changes to registered entities (objects) to the receiver’s parent store.
    ///
    /// - important: Unlike the default behavior of `NSManagedObjectContext`, this method actually propagates
    ///              the changes to the parent context that will try to do the same until the root saving context is reached.
    ///              When and if the root saving context is reached the changes will be merged into its child contexts
    ///              with the exception of the context that originated the saving process.
    ///
    /// - note: If the context does not have changes this method does nothing.
    public override func save() throws {
        guard self.hasChanges else { return }
        
        try super.save()
        
        var error: ErrorType? = nil
        self.rootSavingDataContext.performBlockAndWait {
            self.enableMergeFromRootSavingDataContext = false
            defer { self.enableMergeFromRootSavingDataContext = true }
            
            do {
                try self.rootSavingDataContext.save()
            }
            catch let innerError {
                error = innerError
            }
        }
        
        if let error = error {
            throw error
        }
    }
    
    // MARK: - overrided methods
    
    public override func addObservers() {
        //
        super.addObservers()
        
        // the root data context did save
        self.addObserverForName(NSManagedObjectContextDidSaveNotification, object: self.rootSavingDataContext) { [unowned self] notification in
            guard
                self.enableMergeFromRootSavingDataContext && notification.object is RootSavingDataContext,
                let changeNotificationData = notification.userInfo
            else {
                return
            }
            
            self.performBlockAndWait {
                //
                if let updatedObjects = changeNotificationData[NSUpdatedObjectsKey] as? Set<NSManagedObject> where !updatedObjects.isEmpty {
                    for updatedObject in updatedObjects {
                        self.objectWithID(updatedObject.objectID).willAccessValueForKey(nil) // ensures that a fault has been fired
                    }
                }
                
                //
                self.mergeChangesFromContextDidSaveNotification(notification)
            }
        }
    }
    
}

/// Base class for other **AlecrimCoreData** data contexts.
public class ManagedObjectContext: NSManagedObjectContext {
    
    // MARK: - private properties
    
    private var observers = [NSObjectProtocol]()

    // MARK: - init and deinit
    
    public override init(concurrencyType: NSManagedObjectContextConcurrencyType) {
        super.init(concurrencyType: concurrencyType)
        self.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        self.addObservers()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.removeObservers()
    }

    // MARK: - observers methods
    
    /// Requires super.
    public func addObservers() {
        // this context will save
        self.addObserverForName(NSManagedObjectContextWillSaveNotification, object: self) { notification in
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
    
    public final func addObserverForName(name: String, object: AnyObject, closure: (NSNotification) -> Void) {
        let observer = NSNotificationCenter.defaultCenter().addObserverForName(name, object: object, queue: nil, usingBlock: closure)
        self.observers.append(observer)
    }

}


// MARK: -

@available(*, unavailable, renamed="DataContext")
public class Context {
    
}
