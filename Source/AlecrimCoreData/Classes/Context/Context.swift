//
//  Context.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

@objc(ALCContext)
public class Context: ChildContext {
    
    // MARK: - public properties

    // This will be removed in the next major version.

    private lazy var _defaultBackgroundContext: NSManagedObjectContext = {
        return self.dynamicType(parentContext: self)
    }()
    
    private func defaultCreatedBackgroundContext() -> Self {
        return unsafeBitCast(self._defaultBackgroundContext, self.dynamicType)
    }
    
    // MARK: - init and dealloc
    
    public convenience init() {
        self.init(contextOptions: ContextOptions())
    }
    
    public init(contextOptions: ContextOptions) {
        let rootSavingContext = RootSavingContext(contextOptions: contextOptions)
        super.init(concurrencyType: .MainQueueConcurrencyType, rootSavingContext: rootSavingContext)
        self.name = "Main Thread Context"
    }

    public required init(parentContext: Context) {
        super.init(concurrencyType: .PrivateQueueConcurrencyType, rootSavingContext: parentContext.rootSavingContext)
        self.name = "Background Context"
        self.undoManager = nil
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

// MARK: - BaseContext

public class BaseContext: NSManagedObjectContext {
    
    // MARK: - private properties
    
    private var observers = [NSObjectProtocol]()
    
    
    // MARK: - init and dealloc
    
    public override init(concurrencyType: NSManagedObjectContextConcurrencyType) {
        super.init(concurrencyType: concurrencyType)
        self.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        self.addObservers()
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.removeObservers()
    }
    
    // MARK: - public methods
    
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
    
    // MARK: - private methods
    
    private func addObservers() {
        // this context will save
        self.addObserverForName(NSManagedObjectContextWillSaveNotification, object: self) { notification in
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
    
    private func addObserverForName(name: String, object: AnyObject, closure: (NSNotification!) -> Void) {
        let observer = NSNotificationCenter.defaultCenter().addObserverForName(name, object: object, queue: nil, usingBlock: closure)
        self.observers.append(observer)
    }
    
}

// MARK: - root saving data context

public class RootSavingContext: BaseContext {
    
    private let contextOptions: ContextOptions
    
    public init(contextOptions: ContextOptions) {
        self.contextOptions = contextOptions
        super.init(concurrencyType: .PrivateQueueConcurrencyType)
        
        self.name = "Root Saving Context"
        self.undoManager = nil
        
        // only the root data context has a direct assigned persistent store coordinator
        self.assignPersistentStoreCoordinator()
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func assignPersistentStoreCoordinator() {
        // managed object model
        if let managedObjectModelURL = self.contextOptions.managedObjectModelURL, let managedObjectModel = NSManagedObjectModel(contentsOfURL: managedObjectModelURL) {
            // persistent store coordinator
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
            
            // persistent store
            switch self.contextOptions.storeType {
            case .SQLite:
                if let persistentStoreURL = self.contextOptions.persistentStoreURL,
                    let containerURL = persistentStoreURL.URLByDeletingLastPathComponent {
                        // if the directory does not exist, it will be created
                        var fileManagerError: NSError? = nil
                        if NSFileManager.defaultManager().createDirectoryAtURL(containerURL, withIntermediateDirectories: true, attributes: nil, error: &fileManagerError) {
                            var error: NSError? = nil
                            persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: self.contextOptions.configuration, URL: persistentStoreURL, options: self.contextOptions.options as [NSObject : AnyObject], error: &error)
                            
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
                persistentStoreCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: self.contextOptions.configuration, URL: nil, options: self.contextOptions.options as [NSObject : AnyObject], error: &error)
                
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

// MARK: - ChildContext

public class ChildContext: BaseContext {

    // MARK: - private properties
    
    private var enableMergeFromRootSavingContext = true
    
    // MARK: - public properties
    
    public let rootSavingContext: RootSavingContext
    
    // MARK: - init and dealloc
    
    public init(concurrencyType: NSManagedObjectContextConcurrencyType, rootSavingContext: RootSavingContext) {
        self.rootSavingContext = rootSavingContext
        super.init(concurrencyType: concurrencyType)
        
        self.parentContext = self.rootSavingContext
    }

    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - public overrided methods

    public override func save(error: NSErrorPointer) -> Bool {
        if !self.hasChanges { return true }
        
        var success = super.save(error)
        
        if success {
            self.rootSavingContext.performBlockAndWait {
                self.enableMergeFromRootSavingContext = false
                success = self.rootSavingContext.save(error)
                self.enableMergeFromRootSavingContext = true
            }
        }
        
        return success
    }
    
    // MARK: - private overrided methods
    
    private override func addObservers() {
        //
        super.addObservers()
        
        //
        // the root data context did save
        self.addObserverForName(NSManagedObjectContextDidSaveNotification, object: self.rootSavingContext) { [unowned self] notification in
            if !self.enableMergeFromRootSavingContext {
                return
            }
            
            if let savedContext = notification.object as? RootSavingContext, let changeNotificationData = notification.userInfo {
                self.performBlock {
                    //
                    let updatedObjects = changeNotificationData[NSUpdatedObjectsKey] as? Set<NSManagedObject>
                    if let updatedObjects = updatedObjects where !updatedObjects.isEmpty {
                        for objectObject in updatedObjects {
                            self.objectWithID(objectObject.objectID).willAccessValueForKey(nil) // ensures that a fault has been fired
                        }
                    }
                    
                    //
                    self.mergeChangesFromContextDidSaveNotification(notification)
                }
            }
        }
    }
    
}

// MARK: - BaseContext extensions

extension BaseContext {
    
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

// MARK: - public global functions - background contexts

// This functions will be removed in the next major version.

public func createBackgroundContext<T: Context>(parentContext: T, usingNewBackgroundManagedObjectContext: Bool) -> T {
    if usingNewBackgroundManagedObjectContext {
        return T(parentContext: parentContext)
    }
    else {
        return parentContext.defaultCreatedBackgroundContext()
    }
}

public func performInBackground<T: Context>(parentContext: T, closure: (T) -> Void) {
    performInBackground(parentContext, false, closure)
}

public func performInBackground<T: Context>(parentContext: T, usingNewBackgroundManagedObjectContext: Bool, closure: (T) -> Void) {
    let backgroundContext = createBackgroundContext(parentContext, usingNewBackgroundManagedObjectContext)
    
    backgroundContext.performBlock {
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

