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
    public let managedObjectContext: NSManagedObjectContext! // The underlying managed object context
    
    public init?(stackType: StackType = StackType.SQLite, managedObjectModelName: String? = nil, storeOptions: [NSObject : AnyObject]? = nil) {
        if let stack = Stack(stackType: stackType, managedObjectModelName: managedObjectModelName, storeOptions: storeOptions) {
            self.stack = stack
            self.managedObjectContext = stack.mainManagedObjectContext
        }
        else {
            self.stack = nil
            self.managedObjectContext = nil

            return nil
        }
    }
    
    private init(parentContext: Context) {
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
    public var undoManager: NSUndoManager? { return self.managedObjectContext.undoManager }
    
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
    
    internal func executeAsynchronousFetchRequestWithFetchRequest(fetchRequest: NSFetchRequest, completionHandler: ([AnyObject]?, NSError?) -> Void) -> NSProgress {
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { asynchronousFetchResult in
            completionHandler(asynchronousFetchResult.finalResult, asynchronousFetchResult.operationError)
        }
        
        let moc = self.managedObjectContext
        let progress = NSProgress(totalUnitCount: 1)
        
        progress.becomeCurrentWithPendingUnitCount(1)
        
        moc.performBlock {
            var error: NSError? = nil
            let result = moc.executeRequest(asynchronousFetchRequest, error: &error) as! NSAsynchronousFetchResult
            
            if error != nil {
                completionHandler(nil, error)
            }
        }
        
        progress.resignCurrent()
        
        return progress
    }
    
    internal func executeBatchUpdateRequestWithEntityDescription(entityDescription: NSEntityDescription, propertiesToUpdate: [NSObject : AnyObject], predicate: NSPredicate, completionHandler: (Int, NSError?) -> Void) {
        performInBackground(self) { backgroundContext in
            let batchUpdateRequest = NSBatchUpdateRequest(entity: entityDescription)
            batchUpdateRequest.propertiesToUpdate = propertiesToUpdate
            batchUpdateRequest.predicate = predicate
            batchUpdateRequest.resultType = .UpdatedObjectsCountResultType
            
            let moc = backgroundContext.managedObjectContext
            moc.performBlock {
                var error: NSError? = nil
                let result = moc.executeRequest(batchUpdateRequest, error: &error) as! NSBatchUpdateResult
                
                if error == nil {
                    completionHandler(result.result as! Int, nil)
                }
                else {
                    completionHandler(0, error)
                }
            }
        }
    }
    
}

// MARK: - public global functions

public func performInBackground<T: Context>(parentContext: T, closure: (T) -> Void) {
    let backgroundContext = T(parentContext: parentContext)
    
    backgroundContext.perform {
        closure(backgroundContext)
    }
}
