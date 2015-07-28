//
//  NSManagedObjectContextExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-27.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    /// Asynchronously performs a given closure on the receiver’s queue.
    ///
    /// - parameter closure: The closure to perform.
    ///
    /// - note: Calling this method is the same as calling `performBlock:` method.
    ///
    /// - seealso: `performBlock:`
    public func perform(closure: () -> Void) {
        self.performBlock(closure)
    }
    
    /// Synchronously performs a given closure on the receiver’s queue.
    ///
    /// - parameter closure: The closure to perform
    ///
    /// - note: Calling this method is the same as calling `performBlockAndWait:` method.
    ///
    /// - seealso: `performBlockAndWait:`
    public func performAndWait(closure: () -> Void) {
        self.performBlockAndWait(closure)
    }

}

extension NSManagedObjectContext {
    
    @available(OSX 10.10, iOS 8.0, *)
    internal func executeAsynchronousFetchRequestWithFetchRequest(fetchRequest: NSFetchRequest, completion completionHandler: ([AnyObject]?, NSError?) -> Void) throws {
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { asynchronousFetchResult in
            completionHandler(asynchronousFetchResult.finalResult, asynchronousFetchResult.operationError)
        }
        
        let persistentStoreResult = try self.executeRequest(asynchronousFetchRequest)
        if let _ = persistentStoreResult as? NSAsynchronousFetchResult {
            
        }
        else {
            throw AlecrimCoreDataError.UnexpectedValue(value: persistentStoreResult)
        }
    }
    
}

extension NSManagedObjectContext {
    
    @available(OSX 10.10, iOS 8.0, *)
    internal func executeBatchUpdateRequestWithEntityDescription(entityDescription: NSEntityDescription, propertiesToUpdate: [NSObject : AnyObject], predicate: NSPredicate, completion completionHandler: (Int, ErrorType?) -> Void) {
        let batchUpdateRequest = NSBatchUpdateRequest(entity: entityDescription)
        batchUpdateRequest.propertiesToUpdate = propertiesToUpdate
        batchUpdateRequest.predicate = predicate
        batchUpdateRequest.resultType = .UpdatedObjectsCountResultType
        
        //
        // HAX:
        // The `executeRequest:` method for a batch update only works in the root saving context.
        // If called in a context that has a parent context, both the `batchUpdateResult` and the `error` will be quietly set to `nil` by Core Data.
        //
        
        var moc: NSManagedObjectContext = self
        while moc.parentContext != nil {
            moc = moc.parentContext!
        }
        
        moc.performBlock {
            do {
                let persistentStoreResult = try moc.executeRequest(batchUpdateRequest)
                
                if let batchUpdateResult = persistentStoreResult as? NSBatchUpdateResult {
                    if let count = batchUpdateResult.result as? Int {
                        completionHandler(count, nil)
                    }
                    else {
                        throw AlecrimCoreDataError.UnexpectedValue(value: batchUpdateResult.result)
                    }
                }
                else {
                    throw AlecrimCoreDataError.UnexpectedValue(value: persistentStoreResult)
                }
            }
            catch let error {
                completionHandler(0, error)
            }
        }
    }

    @available(OSX 10.11, iOS 9.0, *)
    internal func executeBatchDeleteRequestWithEntityDescription(entityDescription: NSEntityDescription, objectIDs: [NSManagedObjectID], completion completionHandler: (Int, ErrorType?) -> Void) {
        let batchDeleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
        batchDeleteRequest.resultType = .ResultTypeCount
        
        //
        // HAX:
        // The `executeRequest:` method for a batch delete may only works in the root saving context.
        // If called in a context that has a parent context, both the `batchDeleteResult` and the `error` will be quietly set to `nil` by Core Data.
        //
        
        var moc: NSManagedObjectContext = self
        while moc.parentContext != nil {
            moc = moc.parentContext!
        }
        
        moc.performBlock {
            do {
                let persistentStoreResult = try moc.executeRequest(batchDeleteRequest)
                
                if let batchDeleteResult = persistentStoreResult as? NSBatchDeleteResult {
                    if let count = batchDeleteResult.result as? Int {
                        completionHandler(count, nil)
                    }
                    else {
                        throw AlecrimCoreDataError.UnexpectedValue(value: batchDeleteResult.result)
                    }
                }
                else {
                    throw AlecrimCoreDataError.UnexpectedValue(value: persistentStoreResult)
                }
            }
            catch let error {
                completionHandler(0, error)
            }
        }
    }
    
}
