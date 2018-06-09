//
//  EntityObserver.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 07/06/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

/// A fetch request controller wrapper for one entity only. Can be used as observer for an entity detail presentation, for example.
public final class EntityObserver<EntityType: ManagedObject> {
    
    private let frc: FetchRequestController<EntityType>
    
    fileprivate init(entity: EntityType, propertyName: String, updateHandler didChangeContentClosure: @escaping () -> Void, context: ManagedObjectContext) {
        self.frc = Query<EntityType>(in: context)
            .batchSize(0)
            .filtered(using: Predicate(format: "SELF == %@", argumentArray: [entity]))
            .sorted(by: SortDescriptor(key: propertyName, ascending: true))
            .toFetchRequestController()
        
        self.frc.didChangeContent(closure: didChangeContentClosure)
    }
    
    deinit {
        self.frc.removeAllBindings()
    }
    
}

// MARK: -

extension PersistentContainerType {
    public func observer<EntityType: ManagedObject>(for entity: EntityType, updateHandler: @escaping () -> Void) -> EntityObserver<EntityType> {
        // using any property here is fine, but there must be at least one property
        guard let propertyName = entity.entity.properties.first(where: { $0.isTransient == false })?.name else {
            fatalError("No property found.")
        }
        
        return EntityObserver(entity: entity, propertyName: propertyName, updateHandler: updateHandler, context: self.viewContext)
    }
}
