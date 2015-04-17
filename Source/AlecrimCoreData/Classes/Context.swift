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
    
    private(set) internal var contextOptions: ContextOptions
    private var stack: Stack!
    private(set) public var managedObjectContext: NSManagedObjectContext! // The underlying managed object context

    public init?(contextOptions: ContextOptions? = nil) {
        self.contextOptions = (contextOptions == nil ? ContextOptions() : contextOptions!)
        
        if self.contextOptions.filled {
            // HAX: (vmartinelli) 2015-04-16 -> if filled == true, this constructor was called from the convenience init below and
            //                                  stack and managedObjectContext will be assigned there
            self.stack = nil
            self.managedObjectContext = nil
        }
        else {
            self.contextOptions.fillEmptyOptions()
            
            if let stack = Stack(contextOptions: self.contextOptions) {
                self.stack = stack
                self.managedObjectContext = stack.mainManagedObjectContext
            }
            else {
                self.stack = nil
                self.managedObjectContext = nil
                
                return nil
            }
        }
        
    }
    
    // HAX: (vmartinelli) 2015-04-16 -> EXC_BAD_ACCESS if this contructor is not a convenience init
    //                                  and a property of inherited Context class is called
    private convenience init?(parentContext: Context) {
        self.init(contextOptions: parentContext.contextOptions)
        
        self.contextOptions = parentContext.contextOptions
        self.stack = parentContext.stack
        self.managedObjectContext = parentContext.stack.createBackgroundManagedObjectContext()
    }
    
}

extension Context {
    
    public func save() -> (Bool, NSError?) {
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
    
    #if os(OSX)

    public func commitEditing() -> Bool {
        return self.managedObjectContext.commitEditing()
    }
    
    #endif
    
}

extension Context {
    
    internal func executeFetchRequest(fetchRequest: NSFetchRequest, error: NSErrorPointer) -> [AnyObject]? {
        var objects: [AnyObject]?
        
        self.performAndWait {
            objects = self.managedObjectContext.executeFetchRequest(fetchRequest, error: error)
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
        performInBackground(self) { backgroundContext in
            let batchUpdateRequest = NSBatchUpdateRequest(entity: entityDescription)
            batchUpdateRequest.propertiesToUpdate = propertiesToUpdate
            batchUpdateRequest.predicate = predicate
            batchUpdateRequest.resultType = .UpdatedObjectsCountResultType
            
            let moc = backgroundContext.managedObjectContext
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
    
}

// MARK: - public global functions

public func performInBackground<T: Context>(parentContext: T, closure: (T) -> Void) {
    let backgroundContext = T(parentContext: parentContext)!
    
    backgroundContext.perform {
        closure(backgroundContext)
    }
}
