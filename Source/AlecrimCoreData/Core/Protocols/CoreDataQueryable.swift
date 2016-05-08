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
        
        if let error = error {
            AlecrimCoreDataError.handleError(error)
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
    
    public func sum<U>(@noescape closure: (Self.Item.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Item.self)
        return self.aggregate(using: "sum", attribute: attribute)
    }
    
    public func min<U>(@noescape closure: (Self.Item.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Item.self)
        return self.aggregate(using: "min", attribute: attribute)
    }
    
    public func max<U>(@noescape closure: (Self.Item.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Item.self)
        return self.aggregate(using: "max", attribute: attribute)
    }

    // same as average, for convenience
    public func avg<U>(@noescape closure: (Self.Item.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Item.self)
        return self.aggregate(using: "average", attribute: attribute)
    }

    public func average<U>(@noescape closure: (Self.Item.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Item.self)
        return self.aggregate(using: "average", attribute: attribute)
    }
    
    private func aggregate<U>(using functionName: String, attribute: Attribute<U>) -> U {
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
        
        do {
            let results = try self.dataContext.executeFetchRequest(fetchRequest)
            
            guard let firstResult = results.first as? NSDictionary else { throw AlecrimCoreDataError.unexpectedValue(results) }
            guard let anyObjectValue = firstResult.valueForKey(expressionDescription.name) else { throw AlecrimCoreDataError.unexpectedValue(firstResult) }
            guard let value = anyObjectValue as? U else { throw AlecrimCoreDataError.unexpectedValue(anyObjectValue) }
            
            return value
        }
        catch let error {
            AlecrimCoreDataError.handleError(error)
        }
    }
    
}
