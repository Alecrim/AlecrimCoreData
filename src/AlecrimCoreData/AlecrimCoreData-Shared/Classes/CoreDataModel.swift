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
    
    private let stack: CoreDataStack
    internal let context: NSManagedObjectContext
    
    public init(modelName: String?)
    {
        self.stack = CoreDataStack(modelName: modelName)
        self.context = self.stack.mainContext
    }
    
    private init(parentDataModel: CoreDataModel) {
        self.stack = parentDataModel.stack
        self.context = self.stack.createBackgroundContext()
    }
    
    public class func performInBackground<T: CoreDataModel>(dataModel: T, closure: (T) -> Void) {
        let backgroundDataModel = T(parentDataModel: dataModel)
        backgroundDataModel.perform {
            closure(backgroundDataModel)
        }
    }
    
}

extension CoreDataModel {
    
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

extension CoreDataModel {

    public func perform(closure: () -> Void) {
        self.context.performBlock(closure)
    }
    
    public func performAndWait(closure: () -> Void) {
        self.context.performBlockAndWait(closure)
    }

}

extension CoreDataModel {
    
    /// Treats the property as its current context when needed in expressions.
    public func __conversion() -> NSManagedObjectContext {
        return self.context
    }
    
}

