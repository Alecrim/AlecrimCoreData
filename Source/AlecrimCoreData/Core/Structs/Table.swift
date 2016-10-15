//
//  Table.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-25.
//  Copyright (c) 2014, 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// MARK: -

private var cachedObjectDescriptions = [String : NSEntityDescription]()

private func cachedObjectDescription(for context: NSManagedObjectContext, managedObjectType: NSManagedObject.Type) -> NSEntityDescription {
    let contextClassName = String(describing: type(of: context))
    let managedObjectClassName = String(describing: managedObjectType)
    let cacheKey = "\(contextClassName)|\(managedObjectClassName)"
    
    let entityDescription: NSEntityDescription
    
    if let cachedObjectDescription = cachedObjectDescriptions[cacheKey] {
        entityDescription = cachedObjectDescription
    }
    else {
        let persistentStoreCoordinator = context.persistentStoreCoordinator!
        let managedObjectModel = persistentStoreCoordinator.managedObjectModel
        
        entityDescription = managedObjectModel.entities.filter({ $0.managedObjectClassName.components(separatedBy: ".").last! == managedObjectClassName }).first!
        cachedObjectDescriptions[cacheKey] = entityDescription
    }
    
    return entityDescription
}

// MARK: -


public struct Table<T: NSManagedObject>: TableProtocol {
    
    public typealias Element = T
    
    public let context: NSManagedObjectContext
    public let entityDescription: NSEntityDescription
    
    public var offset: Int = 0
    public var limit: Int = 0
    public var batchSize: Int = PersistentContainerOptions.defaultBatchSize
    
    public var predicate: NSPredicate? = nil
    public var sortDescriptors: [NSSortDescriptor]? = nil
    
    public init(context: NSManagedObjectContext) {
        self.context = context
        self.entityDescription = cachedObjectDescription(for: context, managedObjectType: T.self)
    }
    
}
