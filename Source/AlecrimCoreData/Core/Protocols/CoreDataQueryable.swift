//
//  CoreDataQueryable.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-08-08.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public protocol CoreDataQueryable: GenericQueryable {
    
    var batchSize: Int { get set }

    var dataContext: NSManagedObjectContext { get }
    var entityDescription: NSEntityDescription { get }

    func toFetchRequest() -> NSFetchRequest
    
}

// MARK: - Enumerable

extension CoreDataQueryable {
    
    public func count() -> Int {
        var error: NSError? = nil
        let c = self.dataContext.countForFetchRequest(self.toFetchRequest(), error: &error) // where is the `throws`?
        
        if let _ = error {
            // TODO: throw error?
            return 0
        }
        
        if c != NSNotFound {
            return c
        }
        else {
            return 0
        }
    }
    
}


// MARK: - aggregate

extension CoreDataQueryable {
    
    public func sum<U>(attributeClosure: (Self.Item.Type) -> Attribute<U>) -> U {
        return self.aggregateWithFunctionName("sum", attributeClosure: attributeClosure)
    }
    
    public func min<U>(attributeClosure: (Self.Item.Type) -> Attribute<U>) -> U {
        return self.aggregateWithFunctionName("min", attributeClosure: attributeClosure)
    }
    
    public func max<U>(attributeClosure: (Self.Item.Type) -> Attribute<U>) -> U {
        return self.aggregateWithFunctionName("max", attributeClosure: attributeClosure)
    }

    // same as average, for convenience
    public func avg<U>(attributeClosure: (Self.Item.Type) -> Attribute<U>) -> U {
        return self.aggregateWithFunctionName("average", attributeClosure: attributeClosure)
    }

    public func average<U>(attributeClosure: (Self.Item.Type) -> Attribute<U>) -> U {
        return self.aggregateWithFunctionName("average", attributeClosure: attributeClosure)
    }
    
    private func aggregateWithFunctionName<U>(functionName: String, @noescape attributeClosure: (Self.Item.Type) -> Attribute<U>) -> U {
        let attribute = attributeClosure(Self.Item.self)
        let attributeDescription = self.entityDescription.attributesByName[attribute.___name]!
        
        let keyPathExpression = NSExpression(forKeyPath: attribute.___name)
        let functionExpression = NSExpression(forFunction: "\(functionName):", arguments: [keyPathExpression])
        
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = "___\(functionName)"
        expressionDescription.expression = functionExpression
        expressionDescription.expressionResultType = attributeDescription.attributeType
        
        let fetchRequest = self.toFetchRequest()
        fetchRequest.propertiesToFetch =  [expressionDescription]
        fetchRequest.resultType = NSFetchRequestResultType.DictionaryResultType
        
        let results = try! self.dataContext.executeFetchRequest(fetchRequest)
        
        let value: AnyObject = (results.first as! NSDictionary).valueForKey(expressionDescription.name)!
        if let safeValue = value as? U {
            return safeValue
        }
        else {
            // HAX: try brute force
            return unsafeBitCast(value, U.self)
        }
    }
    
}
