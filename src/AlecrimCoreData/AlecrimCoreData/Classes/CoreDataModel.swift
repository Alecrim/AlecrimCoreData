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
    
    init() {
        self.stack = CoreDataStack(modelName: nil)
    }
    
    init(modelName: String)
    {
        self.stack = CoreDataStack(modelName: modelName)
    }
    
}

extension CoreDataModel {
    
    func save() -> (Bool, NSError?) {
        var success = false
        var error: NSError? = nil
        
        self.stack.context.performBlockAndWait { [unowned self] in
            success = self.stack.context.save(&error)
        }
        
        return (success, error)
    }
    
    func save(completion: (Bool, NSError?) -> Void) {
        let callerQueue = dispatch_get_current_queue()
        
        self.stack.context.performBlock { [unowned self] in
            var error: NSError? = nil
            let success = self.stack.context.save(&error)
            
            dispatch_async(callerQueue) {
                completion(success, error)
            }
        }
    }
    
    func rollback() {
        self.stack.context.rollback()
    }
    
}
