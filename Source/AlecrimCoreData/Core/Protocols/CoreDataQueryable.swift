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
    
    associatedtype Element: NSFetchRequestResult
    
    var batchSize: Int { get set }

    var context: NSManagedObjectContext { get }
    var entityDescription: NSEntityDescription { get }

    func toFetchRequest<ResultType: NSFetchRequestResult>() -> NSFetchRequest<ResultType>
    
}

// MARK: - Enumerable

extension CoreDataQueryable {
    
    public final func count() -> Int {
        do {
            let c = try self.context.count(for: self.toFetchRequest() as NSFetchRequest<Self.Element>)
            
            guard c != NSNotFound else {
                return 0
            }
            
            return c
        }
        catch {
            AlecrimCoreDataError.handleError(error)
        }
    }
    
}


// MARK: - aggregate

extension CoreDataQueryable {
    
    public final func sum<U>(_ closure: (Self.Element.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Element.self)
        return self.aggregate(withFunctionName: "sum", attribute: attribute)
    }
    
    public final func min<U>(_ closure: (Self.Element.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Element.self)
        return self.aggregate(withFunctionName: "min", attribute: attribute)
    }
    
    public final func max<U>(_ closure: (Self.Element.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Element.self)
        return self.aggregate(withFunctionName: "max", attribute: attribute)
    }

    // same as average, for convenience
    public final func avg<U>(_ closure: (Self.Element.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Element.self)
        return self.aggregate(withFunctionName: "average", attribute: attribute)
    }

    public final func average<U>(_ closure: (Self.Element.Type) -> Attribute<U>) -> U {
        let attribute = closure(Self.Element.self)
        return self.aggregate(withFunctionName: "average", attribute: attribute)
    }
    
    private final func aggregate<U>(withFunctionName functionName: String, attribute: Attribute<U>) -> U {
        let attributeDescription = self.entityDescription.attributesByName[attribute.___name]!
        
        let keyPathExpression = NSExpression(forKeyPath: attribute.___name)
        let functionExpression = NSExpression(forFunction: "\(functionName):", arguments: [keyPathExpression])
        
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = "___\(functionName)"
        expressionDescription.expression = functionExpression
        expressionDescription.expressionResultType = attributeDescription.attributeType
        
        let fetchRequest = self.toFetchRequest() as NSFetchRequest<NSDictionary>
        fetchRequest.propertiesToFetch =  [expressionDescription]
        fetchRequest.resultType = NSFetchRequestResultType.dictionaryResultType
        
        do {
            let results: [NSDictionary] = try self.context.fetch(fetchRequest)
            
            guard let firstResult = results.first else { throw AlecrimCoreDataError.unexpectedValue(results) }
            guard let anyObjectValue = firstResult.value(forKey: expressionDescription.name) else { throw AlecrimCoreDataError.unexpectedValue(firstResult) }
            guard let value = anyObjectValue as? U else { throw AlecrimCoreDataError.unexpectedValue(anyObjectValue) }
            
            return value
        }
        catch {
            AlecrimCoreDataError.handleError(error)
        }
    }
    
}
