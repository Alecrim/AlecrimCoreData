//
//  Context.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

@objc(ALCDataContext)
public class Context: NSManagedObjectContext {
    
    // MARK: -
    
    // This will be removed in the next major version.
    
    private var _defaultBackgroundContext: Context?
    private func defaultCreatedBackgroundContext() -> Self? {
        if let defaultBackgroundContext = self._defaultBackgroundContext {
            return unsafeBitCast(defaultBackgroundContext, self.dynamicType)
        }
        
        return nil
    }
    
    // MARK: -
    
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
        self.init(contextOptions: ContextOptions())
    }
    
    public convenience init(contextOptions: ContextOptions) {
        self.init(concurrencyType: .MainQueueConcurrencyType)
        
        self.name = "Main Thread Context"
        self.parentContext = RootSavingDataContext(rootSavingDataContextOptions: contextOptions)
    }
    
    // background context
    
    public convenience init(parentContext: NSManagedObjectContext) {
        self.init(concurrencyType: .PrivateQueueConcurrencyType)
        
        if let parentDataContext = parentContext as? Context, let rootSavingDataContext = parentDataContext.rootSavingDataContext {
            self.name = "Background Context " + String(rootSavingDataContext.childDataContexts.count)
            self.parentContext = rootSavingDataContext
        }
        else {
            self.parentContext = parentContext
        }
        
        self.undoManager = nil
    }
    
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func save(error: NSErrorPointer) -> Bool {
        if !self.hasChanges {
            return true
        }
        
        self.rootSavingDataContext?.savedChildContext = self
        
        var success = super.save(error)
        
        if success {
            if let parentContext = self.parentContext {
                parentContext.performBlockAndWait {
                    success = parentContext.save(error)
                }
            }
        }
        
        return success
    }
    
    public func save() -> (success: Bool, error: NSError?) {
        var error: NSError? = nil
        let success = self.save(&error)
        
        return (success, error)
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
            if let notificationContext = notification.object as? NSManagedObjectContext where !notificationContext.insertedObjects.isEmpty {
                notificationContext.obtainPermanentIDsForObjects(Array(notificationContext.insertedObjects), error: nil)
            }
        }
    }
    
    private func removeObservers() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        for observer in self.observers {
            notificationCenter.removeObserver(observer)
        }
    }
    
    private func addObserverForName(name: String, object: AnyObject? = nil, closure: (NSNotification!) -> Void) {
        let observer = NSNotificationCenter.defaultCenter().addObserverForName(name, object: object ?? self, queue: nil, usingBlock: closure)
        self.observers.append(observer)
    }
    
}

extension Context {
    
    internal func executeAsynchronousFetchRequestWithFetchRequest(fetchRequest: NSFetchRequest, completionHandler: ([AnyObject]?, NSError?) -> Void) -> FetchAsyncHandler {
        //
        var completionHandlerCalled = false
        
        //
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { asynchronousFetchResult in
            if !completionHandlerCalled {
                completionHandlerCalled = true
                completionHandler(asynchronousFetchResult.finalResult, asynchronousFetchResult.operationError)
            }
        }
        
        //
        let handler = FetchAsyncHandler(asynchronousFetchRequest: asynchronousFetchRequest)
        
        //
        var error: NSError? = nil
        if handler.cancelled {
            completionHandlerCalled = true
            completionHandler(nil, NSError(domain: "com.alecrim.AlecrimCoreData", code: NSUserCancelledError, userInfo: nil))
        }
        else {
            handler.foolProgress.becomeCurrentWithPendingUnitCount(1)
            handler.asynchronousFetchResult = self.executeRequest(asynchronousFetchRequest, error: &error) as? NSAsynchronousFetchResult
            handler.foolProgress.resignCurrent()
            
            if error != nil {
                completionHandlerCalled = true
                completionHandler(nil, error)
            }
            else if handler.asynchronousFetchResult?.operationError != nil {
                completionHandlerCalled = true
                completionHandler(nil, handler.asynchronousFetchResult!.operationError)
            }
        }
        
        //
        return handler
    }
    
    internal func executeBatchUpdateRequestWithEntityDescription(entityDescription: NSEntityDescription, propertiesToUpdate: [NSObject : AnyObject], predicate: NSPredicate, completionHandler: (Int, NSError?) -> Void) {
        let batchUpdateRequest = NSBatchUpdateRequest(entity: entityDescription)
        batchUpdateRequest.propertiesToUpdate = propertiesToUpdate
        batchUpdateRequest.predicate = predicate
        batchUpdateRequest.resultType = .UpdatedObjectsCountResultType
        
        //
        // HAX:
        // The `executeRequest:` method for a batch update only works in the root saving context.
        // If called in a context that has a parent context, both the `batchUpdateResult` and the `error` will be quietly set to `nil` by Core Data.
        //
        
        var moc: NSManagedObjectContext = self
        while moc.parentContext != nil {
            moc = moc.parentContext!
        }
        
        moc.performBlock {
            var error: NSError? = nil
            
            if let batchUpdateResult = moc.executeRequest(batchUpdateRequest, error: &error) as? NSBatchUpdateResult, let count = batchUpdateResult.result as? Int {
                completionHandler(count, nil)
            }
            else {
                completionHandler(0, error ?? alecrimCoreDataError())
            }
        }
    }
    
}

private class RootSavingDataContext: Context {
    
    private static let genericError = alecrimCoreDataError()
    private static let savedChildContextUserInfoKey = "com.alecrim.AlecrimCoreData.DataContext.SavedChildContext"
    
    private let rootSavingDataContextOptions: ContextOptions
    
    private let childDataContextHashTable = NSHashTable.weakObjectsHashTable()
    private var childDataContexts: [NSManagedObjectContext] { return self.childDataContextHashTable.allObjects as! [Context] }
    
    private var savedChildContext: NSManagedObjectContext? {
        get {
            return self.userInfo![RootSavingDataContext.savedChildContextUserInfoKey] as? NSManagedObjectContext
        }
        set {
            if newValue == nil {
                self.userInfo!.removeObjectForKey(RootSavingDataContext.savedChildContextUserInfoKey)
            }
            else if self.savedChildContext == nil { // do not assign if previous value is not nil
                self.userInfo![RootSavingDataContext.savedChildContextUserInfoKey] = newValue
            }
        }
    }
    
    private init(rootSavingDataContextOptions: ContextOptions) {
        self.rootSavingDataContextOptions = rootSavingDataContextOptions
        super.init(concurrencyType: .PrivateQueueConcurrencyType)
        
        self.name = "Root Saving Context"
        self.undoManager = nil
        
        // only the root data context has a direct assigned persistent store coordinator
        self.assignPersistentStoreCoordinator()
    }
    
    private required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private override func addObservers() {
        super.addObservers()
        
        // the root data context did save
        self.addObserverForName(NSManagedObjectContextDidSaveNotification) { notification in
            if let notificationRootSavingDataContext = notification.object as? RootSavingDataContext where notificationRootSavingDataContext.childDataContexts.count > 0,
                let changeNotificationData = notification.userInfo {
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
    }
    
    private func assignPersistentStoreCoordinator() {
        // managed object model
        if let managedObjectModelURL = self.rootSavingDataContextOptions.managedObjectModelURL, let managedObjectModel = NSManagedObjectModel(contentsOfURL: managedObjectModelURL) {
            // persistent store coordinator
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
            
            // persistent store
            switch self.rootSavingDataContextOptions.storeType {
            case .SQLite:
                if let persistentStoreURL = self.rootSavingDataContextOptions.persistentStoreURL,
                    let containerURL = persistentStoreURL.URLByDeletingLastPathComponent {
                        // if the directory does not exist, it will be created
                        var fileManagerError: NSError? = nil
                        if NSFileManager.defaultManager().createDirectoryAtURL(containerURL, withIntermediateDirectories: true, attributes: nil, error: &fileManagerError) {
                            var error: NSError? = nil
                            persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: self.rootSavingDataContextOptions.configuration, URL: persistentStoreURL, options: self.rootSavingDataContextOptions.options as [NSObject : AnyObject], error: &error)
                            
                            if let error = error {
                                var handled = false
                                
                                if error.domain == NSCocoaErrorDomain {
                                    let migrationErrorCodes = [NSPersistentStoreIncompatibleVersionHashError, NSMigrationMissingSourceModelError, NSMigrationError]
                                    
                                    if contains(migrationErrorCodes, error.code) {
                                        handled = self.handleMigrationError(error)
                                    }
                                }
                                
                                if !handled {
                                    return
                                }
                            }
                        }
                        else {
                            return
                        }
                        
                }
                else {
                    // throws RootSavingDataContext.genericError
                    return
                }
                
            case .InMemory:
                var error: NSError? = nil
                persistentStoreCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: self.rootSavingDataContextOptions.configuration, URL: nil, options: self.rootSavingDataContextOptions.options as [NSObject : AnyObject], error: &error)
                
                if error != nil {
                    return
                }
            }
            
            //
            self.persistentStoreCoordinator = persistentStoreCoordinator
        }
        else {
            // throws RootSavingDataContext.genericError
            return
        }
    }
    
    private func handleMigrationError(error: NSError) -> Bool {
        return false
    }
    
}

// MARK: - public global functions - background contexts

// This functions will be removed in the next major version.

public func createBackgroundContext<T: Context>(parentContext: T, usingNewBackgroundManagedObjectContext: Bool) -> T {
    if !usingNewBackgroundManagedObjectContext {
        if let defaultBackgroundContext = parentContext.defaultCreatedBackgroundContext() {
            return defaultBackgroundContext
        }
    }
    
    let backgroundContext = T(parentContext: parentContext)
    
    if !usingNewBackgroundManagedObjectContext {
        parentContext._defaultBackgroundContext = backgroundContext
    }
    
    return backgroundContext
}

public func performInBackground<T: Context>(parentContext: T, closure: (T) -> Void) {
    performInBackground(parentContext, false, closure)
}

public func performInBackground<T: Context>(parentContext: T, usingNewBackgroundManagedObjectContext: Bool, closure: (T) -> Void) {
    let backgroundContext = createBackgroundContext(parentContext, usingNewBackgroundManagedObjectContext)
    
    backgroundContext.perform {
        closure(backgroundContext)
    }
}


// MARK: - internal global functions - error handling

internal func alecrimCoreDataError(code: Int = NSCoreDataError, userInfo: [NSObject : AnyObject]? = nil) -> NSError {
    return NSError(domain: "com.alecrim.AlecrimCoreData", code: code, userInfo: userInfo)
}

internal func alecrimCoreDataHandleError(error: NSError?, filename: String = __FILE__, line: Int = __LINE__, funcname: String = __FUNCTION__) {
    if let error = error where error.code != NSUserCancelledError {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss:SSS"
        
        let process = NSProcessInfo.processInfo()
        let threadId = NSThread.isMainThread() ? "main" : "background"
        
        let string = "\(dateFormatter.stringFromDate(NSDate())) \(process.processName) [\(process.processIdentifier):\(threadId)] \(filename.lastPathComponent)(\(line)) \(funcname):\r\t\(error)\n"
        println(string)
    }
}

