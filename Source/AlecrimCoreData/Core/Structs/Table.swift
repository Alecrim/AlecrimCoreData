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

public struct Table<T: NSManagedObject>: TableProtocol {
    
    public typealias Item = T
    
    public let dataContext: NSManagedObjectContext
    public let entityDescription: NSEntityDescription
    
    public var offset: Int = 0
    public var limit: Int = 0
    public var batchSize: Int = DataContextOptions.defaultBatchSize
    
    public var predicate: NSPredicate? = nil
    public var sortDescriptors: [NSSortDescriptor]? = nil
    
    public init(dataContext: NSManagedObjectContext) {
        self.dataContext = dataContext
        self.entityDescription = dataContext.persistentStoreCoordinator!
            .cachedEntityDescription(for: dataContext, managedObjectType: T.self)
    }
    
}

// MARK: - CachedEntityDescriptions

extension NSPersistentStoreCoordinator {
    
    private struct AssociatedKeys {
        static var CachedEntityDescriptions = "Alecrim_cachedEntityDescriptions"
    }
    
    private var cachedEntityDescriptions: [String : NSEntityDescription] {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.CachedEntityDescriptions)
                as? [String : NSEntityDescription] ?? [:]
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.CachedEntityDescriptions,
                newValue as NSDictionary?,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    @warn_unused_result
    private func cachedEntityDescription(for dataContext: NSManagedObjectContext, managedObjectType: NSManagedObject.Type) -> NSEntityDescription {
        let dataContextClassName = String(dataContext.dynamicType)
        let managedObjectClassName = String(managedObjectType)
        let cacheKey = "\(dataContextClassName)|\(managedObjectClassName)"
        
        let entityDescription: NSEntityDescription
        
        if let cachedEntityDescription = cachedEntityDescriptions[cacheKey] {
            entityDescription = cachedEntityDescription
        }
        else {
            
            entityDescription =
                managedObjectModel.entities
                    .filter({
                        $0.managedObjectClassName.componentsSeparatedByString(".").last! == managedObjectClassName
                    })
                    .first!
            
            cachedEntityDescriptions[cacheKey] = entityDescription
        }
        
        return entityDescription
    }
    
}