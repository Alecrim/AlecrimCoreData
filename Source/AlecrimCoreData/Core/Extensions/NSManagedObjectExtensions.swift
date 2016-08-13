//
//  NSManagedObjectExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-24.
//  Copyright (c) 2014, 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {

    public func inContext(otherContext: NSManagedObjectContext) throws -> Self {
        if self.managedObjectContext === otherContext {
            return self
        }
        
        if self.objectID.temporaryID {
            try otherContext.obtainPermanentIDsForObjects([self])
        }
        
        let otherManagedObject = try otherContext.existingObjectWithID(self.objectID)
        
        return unsafeBitCast(otherManagedObject, self.dynamicType)
    }
    
}

extension NSManagedObject {
    
    public func delete() {
        self.managedObjectContext!.deleteObject(self)
    }
    
    public func refresh(mergingChanges mergeChanges: Bool = true) {
        self.managedObjectContext!.refreshObject(self, mergeChanges: mergeChanges)
    }

}

extension NSManagedObject {
    
    public class func isIn(values: Set<NSManagedObject>) -> NSComparisonPredicate {
        let rightExpressionConstantValues = values.map { NSExpression(forConstantValue: $0.objectID) }
        let rightExpression = NSExpression(forAggregate: rightExpressionConstantValues)
        let leftExpression = NSExpression(forKeyPath: "objectID")
        
        return NSComparisonPredicate(
            leftExpression: leftExpression,
            rightExpression: rightExpression,
            modifier: .DirectPredicateModifier,
            type: .InPredicateOperatorType,
            options: NSComparisonPredicateOptions()
        )
    }
    
}