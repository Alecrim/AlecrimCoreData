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
        if !self.stack.context.hasChanges {
            return (true, nil)
        }
        
        var success = false
        var error: NSError? = nil
        
        self.stack.context.performBlockAndWait { [unowned self] in
            success = self.stack.context.save(&error)
        }
        
        if (success) {
            self.stack.savingContext.performBlockAndWait { [unowned self] in
                success = self.stack.savingContext.save(&error)
            }
        }
        
        return (success, error)
    }
    
    func save(completion: (Bool, NSError?) -> Void) {
        if !self.stack.context.hasChanges {
            completion(true, nil)
            return
        }
        
        let callerQueue = dispatch_get_current_queue()
        
        self.stack.context.performBlock { [unowned self] in
            var error: NSError? = nil
            let success = self.stack.context.save(&error)
            
            if success {
                self.stack.savingContext.performBlock { [unowned self] in
                    var error: NSError? = nil
                    let success = self.stack.savingContext.save(&error)
                    
                    dispatch_async(callerQueue) {
                        completion(success, error)
                    }
                }
            }
            else {
                dispatch_async(callerQueue) {
                    completion(success, error)
                }
            }
        }
    }
    
    func rollback() {
        self.stack.context.rollback()
    }
    
}
