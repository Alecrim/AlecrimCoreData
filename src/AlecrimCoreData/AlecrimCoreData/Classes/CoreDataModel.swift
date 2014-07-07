//
//  CoreDataModel.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

class CoreDataModel {
    
    let stack: CoreDataStack
    let context: NSManagedObjectContext
    
    init() {
        self.stack = CoreDataStack(modelName: nil)
        self.context = self.stack.mainContext
    }
    
    init(modelName: String)
    {
        self.stack = CoreDataStack(modelName: modelName)
        self.context = self.stack.mainContext
    }
    
    init(parentDataModel: CoreDataModel) {
        self.stack = parentDataModel.stack
        self.context = self.stack.createBackgroundContext()
    }
    
//    deinit {
//        println("deinit - CoreDataModel")
//    }
}

extension CoreDataModel {
    
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

//extension CoreDataModel {
//    
//    func performInBackground<T: CoreDataModel>(closure: (T) -> Void) {
//        let backgroundDataModel = T(parentDataModel: self)
//        closure(backgroundDataModel)
//    }
//    
//}

func usingBackgroundDataModelFrom<T: CoreDataModel>(dataModel: T, closure: (T) -> Void) {
    let backgroundDataModel = T(parentDataModel: dataModel)
    backgroundDataModel.context.performBlock {
        closure(backgroundDataModel)
    }
}

