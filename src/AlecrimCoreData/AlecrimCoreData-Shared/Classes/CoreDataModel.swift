//
//  CoreDataModel.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public class CoreDataModel {
    
    // MARK: private
    private let stack: CoreDataStack

    // MARK: internal
    internal let context: NSManagedObjectContext
    
    // MARK: init and dealloc
    public init() {
        self.stack = CoreDataStack(modelName: nil)
        self.context = self.stack.mainContext
    }
    
    public init(modelName: String)
    {
        self.stack = CoreDataStack(modelName: modelName)
        self.context = self.stack.mainContext
    }
    
}

public extension CoreDataModel {
    
    public func save() -> (Bool, NSError?) {
        return self.stack.saveContext(self.context)
    }
    
    public func save(completion: (Bool, NSError?) -> Void) {
        self.stack.saveContext(self.context, completion: completion)
    }
    
    public func saveEventually() {
        self.stack.saveContext(self.context, completion: nil)
    }
    
    public func rollback() {
        self.context.rollback()
    }
    
}

public extension CoreDataModel {

    public func perform(closure: (NSManagedObjectContext) -> Void) {
        self.context.performBlock { [unowned self] in
            closure(self.context)
        }
    }

    public func performInBackground(closure: (NSManagedObjectContext) -> Void) {
        let backgroundContext = self.stack.createBackgroundContext()
        backgroundContext.performBlock {
            closure(backgroundContext)
        }
    }
    
}
