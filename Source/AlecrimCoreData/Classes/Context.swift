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
    
    public let managedObjectContext: NSManagedObjectContext! // The underlying managed object context
    private let stack: Stack!
    
    public init?(managedObjectModelName: String? = nil, stackType: StackType = StackType.SQLite) {
        if let stack = Stack(managedObjectModelName: managedObjectModelName, stackType: stackType) {
            self.stack = stack
        }
        else {
            return nil
        }
        
        self.managedObjectContext = self.stack.mainManagedObjectContext
    }
    
    private init(parentContext: Context) {
        self.stack = parentContext.stack
        self.managedObjectContext = parentContext.stack.createBackgroundManagedObjectContext()
    }
    
}

extension Context {
    
    public func save() -> Bool {
        let (success, _) = self.save()
        return success
    }

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

// MARK: - public global functions

public func performInBackground<T: Context>(parentContext: T, closure: (T) -> Void) {
    let backgroundContext = T(parentContext: parentContext)
    
    backgroundContext.perform {
        closure(backgroundContext)
    }
}
