//
//  FetchedResultsSectionInfo.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 12/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public final class FetchedResultsSectionInfo<Entity: ManagedObject> {
    
    private let rawValue: NSFetchedResultsSectionInfo
    
    /// The name of the section.
    public var name: String { return self.rawValue.name }
    
    /// The index title of the section.
    public var indexTitle: String? { return self.rawValue.indexTitle }
    
    /// The number of entities (rows) in the section.
    public var numberOfObjects: Int { return self.rawValue.numberOfObjects }
    
    /// The array of entities in the section.
    public var objects: [Entity] {
        guard let result = self.rawValue.objects as? [Entity] else {
            fatalError("performFetch: hasn't been called.")
        }
        
        return result
    }
    
    internal init(rawValue: NSFetchedResultsSectionInfo) {
        self.rawValue = rawValue
    }
    
}

