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
        self.entityDescription = context.persistentStoreCoordinator!.cachedEntityDescription(for: T.self)
    }
    
}

// MARK: - Cached Entity Descriptions

extension NSPersistentStoreCoordinator {
    
    fileprivate func cachedEntityDescription(for managedObjectType: NSManagedObject.Type) -> NSEntityDescription {
        let managedObjectClassName = String(describing: managedObjectType)
        let entityDescription: NSEntityDescription
        
        if let cachedEntityDescription = self.cachedEntityDescriptions[managedObjectClassName] as? NSEntityDescription {
            entityDescription = cachedEntityDescription
        }
        else {
            entityDescription = self.managedObjectModel.entities
                .filter {
                    $0.managedObjectClassName.components(separatedBy: ".").last! == managedObjectClassName }
                .first!
            
            self.cachedEntityDescriptions[managedObjectClassName] = entityDescription
        }
        
        return entityDescription
    }
    
    //
    
    private struct AssociatedKeys {
        static var cachedEntityDescriptions = "com.alecrim.AlecrimCoreData.cachedEntityDescriptions"
    }
    
    private var cachedEntityDescriptions: NSMutableDictionary {
        get {
            if let dictionary = objc_getAssociatedObject(self, &AssociatedKeys.cachedEntityDescriptions) as? NSMutableDictionary {
                return dictionary
            }
            else {
                let dictionary = NSMutableDictionary()
                objc_setAssociatedObject(self, &AssociatedKeys.cachedEntityDescriptions, dictionary, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                
                return dictionary
            }
        }
    }

}
