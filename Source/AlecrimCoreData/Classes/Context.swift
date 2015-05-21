//
//  Context.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public class Context {
    
    private let stack: Stack!
    public let managedObjectContext: NSManagedObjectContext!    // the underlying managed object context
    
    private var ___background: Bool = false                     // background context machinery (you did not see it)
    
    internal var contextOptions: ContextOptions { return self.stack.contextOptions }

    public required init?(contextOptions: ContextOptions? = nil) {
        let stackContextOptions = (contextOptions == nil ? ContextOptions() : contextOptions!)
        stackContextOptions.fillEmptyOptions()
        
        var stack = stackContextOptions.___stack
        if stack == nil {
            stack = Stack(contextOptions: stackContextOptions)
            self.managedObjectContext = stack?.mainManagedObjectContext
        }
        else {
            if stackContextOptions.___stackUsesNewBackgroundManagedObjectContext {
                self.managedObjectContext = stack?.createBackgroundManagedObjectContext()
                stackContextOptions.___stackUsesNewBackgroundManagedObjectContext = false
            }
            else {
                self.managedObjectContext = stack?.backgroundManagedObjectContext
            }
            
            self.___background = true
            stackContextOptions.___stack = nil
        }
        
        self.stack = stack
    }
    
    public init?(rootManagedObjectContext: NSManagedObjectContext, mainManagedObjectContext: NSManagedObjectContext) {
        if let coordinator = rootManagedObjectContext.persistentStoreCoordinator, let store = coordinator.persistentStores.first as? NSPersistentStore {
            var stackType: StackType! = nil
            if store.type == NSSQLiteStoreType {
                stackType = .SQLite
            }
            else if store.type == NSInMemoryStoreType {
                stackType = .InMemory
            }

            if stackType != nil {
                let stackContextOptions = ContextOptions(stackType: stackType, managedObjectModelName: nil, storeOptions: store.options)
                stackContextOptions.fillEmptyOptions(customConfiguration: true)
                
                if let stack = Stack(rootManagedObjectContext: rootManagedObjectContext, mainManagedObjectContext: mainManagedObjectContext, contextOptions: stackContextOptions) {
                    self.stack = stack
                    self.managedObjectContext = stack.mainManagedObjectContext
                }
                else {
                    self.stack = nil
                    self.managedObjectContext = nil
                    
                    return nil
                }
            }
            else {
                self.stack = nil
                self.managedObjectContext = nil
                
                return nil
            }
        }
        else {
            self.stack = nil
            self.managedObjectContext = nil
            
            return nil
        }
        
    }
}

extension Context {
    
    public func save() -> (success: Bool, error: NSError?) {
        return self.stack.saveManagedObjectContext(self.managedObjectContext)
    }
    
}

extension Context {
    
    public func undo() {
        self.managedObjectContext.undo()
    }
    
    public func redo() {
        self.managedObjectContext.redo()
    }
    
    public func reset() {
        self.managedObjectContext.reset()
    }
    
    public func rollback() {
        self.managedObjectContext.rollback()
    }
    
}

extension Context {
    
    public func perform(closure: () -> Void) {
        self.managedObjectContext.performBlock(closure)
    }
    
    public func performAndWait(closure: () -> Void) {
        self.managedObjectContext.performBlockAndWait(closure)
    }
    
}

extension Context {

    public var hasChanges: Bool { return self.managedObjectContext.hasChanges }
    
    public var undoManager: NSUndoManager? {
        get {
            return self.managedObjectContext.undoManager
        }
        set {
            self.managedObjectContext.undoManager = newValue
        }
    }

}

#if os(OSX)

extension Context {

    public func commitEditing() -> Bool {
        return self.managedObjectContext.commitEditing()
    }
    
    public func discardEditing() {
        self.managedObjectContext.discardEditing()
    }

}
    
#endif


extension Context {
    
    internal func executeFetchRequest(fetchRequest: NSFetchRequest, error: NSErrorPointer) -> [AnyObject]? {
        var objects: [AnyObject]?
        
        if self.___background {
            // already in "performBlock"
            objects = self.managedObjectContext.executeFetchRequest(fetchRequest, error: error)
        }
        else {
            self.managedObjectContext.performBlockAndWait {
                objects = self.managedObjectContext.executeFetchRequest(fetchRequest, error: error)
            }
        }
        
        return objects
    }
    
    internal func executeAsynchronousFetchRequestWithFetchRequest(fetchRequest: NSFetchRequest, completionClosure: ([AnyObject]?, NSError?) -> Void) -> NSProgress {
        var completionClosureCalled = false
        
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { asynchronousFetchResult in
            if !completionClosureCalled {
                completionClosureCalled = true
                completionClosure(asynchronousFetchResult.finalResult, asynchronousFetchResult.operationError)
            }
        }
        
        let moc = self.managedObjectContext
        let progress = NSProgress(totalUnitCount: 1)
        
        progress.becomeCurrentWithPendingUnitCount(1)
        
        moc.performBlock {
            var error: NSError? = nil
            let asynchronousFetchResult = moc.executeRequest(asynchronousFetchRequest, error: &error) as! NSAsynchronousFetchResult
            
            if error != nil {
                completionClosureCalled = true
                completionClosure(nil, error)
            }
            else if asynchronousFetchResult.operationError != nil {
                completionClosureCalled = true
                completionClosure(nil, asynchronousFetchResult.operationError)
            }
        }
        
        progress.resignCurrent()
        
        return progress
    }
    
    internal func executeBatchUpdateRequestWithEntityDescription(entityDescription: NSEntityDescription, propertiesToUpdate: [NSObject : AnyObject], predicate: NSPredicate, completionClosure: (Int, NSError?) -> Void) {
        let batchUpdateRequest = NSBatchUpdateRequest(entity: entityDescription)
        batchUpdateRequest.propertiesToUpdate = propertiesToUpdate
        batchUpdateRequest.predicate = predicate
        batchUpdateRequest.resultType = .UpdatedObjectsCountResultType
        
        let moc = self.stack.backgroundManagedObjectContext
        moc.performBlock {
            var error: NSError? = nil
            let batchUpdateResult = moc.executeRequest(batchUpdateRequest, error: &error) as! NSBatchUpdateResult
            
            if error != nil {
                completionClosure(0, error)
            }
            else {
                completionClosure(batchUpdateResult.result as! Int, nil)
            }
        }
    }
    
}

// MARK: - public global functions

public func performInBackground<T: Context>(parentContext: T, closure: (T) -> Void) {
    performInBackground(parentContext, false, closure)
}

public func performInBackground<T: Context>(parentContext: T, createNewBackgroundManagedObjectContext: Bool, closure: (T) -> Void) {
    parentContext.contextOptions.___stack = parentContext.stack
    parentContext.contextOptions.___stackUsesNewBackgroundManagedObjectContext = createNewBackgroundManagedObjectContext
    let backgroundContext = T(contextOptions: parentContext.contextOptions)!
    
    backgroundContext.perform {
        if !createNewBackgroundManagedObjectContext {
            backgroundContext.managedObjectContext.reset()
        }
        
        closure(backgroundContext)
    }
}

