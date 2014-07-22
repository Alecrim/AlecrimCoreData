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
    
    func save() -> (Bool, NSError?) {
        return self.stack.saveContext(self.context)
    }
    
    func save(completion: (Bool, NSError?) -> Void) {
        self.stack.saveContext(self.context, completion: completion)
    }
    
    func saveEventually() {
        self.stack.saveContext(self.context, completion: nil)
    }
    
    func rollback() {
        self.context.rollback()
    }
    
}

public extension CoreDataModel {

    func perform(closure: (NSManagedObjectContext) -> Void) {
        let localContext = self.context
        localContext.performBlock {
            closure(localContext)
        }
    }

    func performInBackground(closure: (NSManagedObjectContext) -> Void) {
        let localContext = self.stack.createBackgroundContext()
        localContext.performBlock {
            closure(localContext)
        }
    }
    
}
