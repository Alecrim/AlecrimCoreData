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
