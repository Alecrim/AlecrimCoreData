//
//  NSManagedObjectContextExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-27.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

// TODO: this was never publicly available, find a nice way to implement

//import Foundation
//import CoreData
//
//extension NSManagedObjectContext {
//    
//    internal func executeAsynchronousFetchRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>, completion completionHandler: ([AnyObject]?, NSError?) -> Void) throws {
//        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) { asynchronousFetchResult in
//            completionHandler(asynchronousFetchResult.finalResult, asynchronousFetchResult.operationError)
//        }
//        
//        let persistentStoreResult = try self.execute(asynchronousFetchRequest)
//        if let _ = persistentStoreResult as? NSAsynchronousFetchResult<NSFetchRequestResult> {
//            
//        }
//        else {
//            throw AlecrimCoreDataError.unexpectedValue(persistentStoreResult)
//        }
//    }
//    
//}
//
//extension NSManagedObjectContext {
//    
//    internal func executeBatchUpdateRequest(entityDescription: NSEntityDescription, propertiesToUpdate: [NSObject : AnyObject], predicate: NSPredicate, completion completionHandler: (Int, Error?) -> Void) {
//        let batchUpdateRequest = NSBatchUpdateRequest(entity: entityDescription)
//        batchUpdateRequest.propertiesToUpdate = propertiesToUpdate
//        batchUpdateRequest.predicate = predicate
//        batchUpdateRequest.resultType = .updatedObjectsCountResultType
//        
//        //
//        // HAX:
//        // The `executeRequest:` method for a batch update only works in the root saving context.
//        // If called in a context that has a parent context, both the `batchUpdateResult` and the `error` will be quietly set to `nil` by Core Data.
//        //
//        
//        var moc: NSManagedObjectContext = self
//        while moc.parent != nil {
//            moc = moc.parent!
//        }
//        
//        moc.perform {
//            do {
//                let persistentStoreResult = try moc.execute(batchUpdateRequest)
//                
//                if let batchUpdateResult = persistentStoreResult as? NSBatchUpdateResult {
//                    if let count = batchUpdateResult.result as? Int {
//                        completionHandler(count, nil)
//                    }
//                    else {
//                        throw AlecrimCoreDataError.unexpectedValue(batchUpdateResult.result)
//                    }
//                }
//                else {
//                    throw AlecrimCoreDataError.unexpectedValue(persistentStoreResult)
//                }
//            }
//            catch {
//                completionHandler(0, error)
//            }
//        }
//    }
//
//    internal func executeBatchDeleteRequest(entityDescription: NSEntityDescription, objectIDs: [NSManagedObjectID], completion completionHandler: (Int, Error?) -> Void) {
//        let batchDeleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
//        batchDeleteRequest.resultType = .resultTypeCount
//        
//        //
//        // HAX:
//        // The `executeRequest:` method for a batch delete may only works in the root saving context.
//        // If called in a context that has a parent context, both the `batchDeleteResult` and the `error` will be quietly set to `nil` by Core Data.
//        //
//        
//        var moc: NSManagedObjectContext = self
//        while moc.parent != nil {
//            moc = moc.parent!
//        }
//        
//        moc.perform {
//            do {
//                let persistentStoreResult = try moc.execute(batchDeleteRequest)
//                
//                if let batchDeleteResult = persistentStoreResult as? NSBatchDeleteResult {
//                    if let count = batchDeleteResult.result as? Int {
//                        completionHandler(count, nil)
//                    }
//                    else {
//                        throw AlecrimCoreDataError.unexpectedValue(batchDeleteResult.result)
//                    }
//                }
//                else {
//                    throw AlecrimCoreDataError.unexpectedValue(persistentStoreResult)
//                }
//            }
//            catch {
//                completionHandler(0, error)
//            }
//        }
//    }
//    
//}
