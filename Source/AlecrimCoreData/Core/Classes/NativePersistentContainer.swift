//
//  NativePersistentContainer.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-10-14.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// MARK: -

@available(iOS 10.0, *) // to make CocoaPods happy
@available(macOSApplicationExtension 10.12, iOSApplicationExtension 10.0, tvOSApplicationExtension 10.0, watchOSApplicationExtension 3.0, *)
internal class NativePersistentContainer: NSPersistentContainer, UnderlyingPersistentContainer {
    
    private let contextType: NSManagedObjectContext.Type
    private let _viewContext: NSManagedObjectContext
    
    internal override var viewContext: NSManagedObjectContext { return self._viewContext }
    
    internal required init(name: String, managedObjectModel model: NSManagedObjectModel, contextType: NSManagedObjectContext.Type) {
        self.contextType = contextType
        self._viewContext = self.contextType.init(concurrencyType: .mainQueueConcurrencyType)
        
        super.init(name: name, managedObjectModel: model)
        
        self._viewContext.persistentStoreCoordinator = self.persistentStoreCoordinator
    }
    
    internal override func newBackgroundContext() -> NSManagedObjectContext {
        let context = self.contextType.init(concurrencyType: .privateQueueConcurrencyType)
        
        if let parentContext = self.viewContext.parent {
            context.parent = parentContext
        }
        else {
            context.persistentStoreCoordinator = self.persistentStoreCoordinator
        }

        return context
    }
    
    @available(*, unavailable)
    internal override func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
        fatalError()
    }

    internal var alc_persistentStoreDescriptions: [PersistentStoreDescription] {
        get { return self.persistentStoreDescriptions }
        set {
            guard let newValue = newValue as? [NSPersistentStoreDescription] else {
                fatalError("Unexpected persistent store description type.")
            }
            
            self.persistentStoreDescriptions = newValue
        }
    }
    
    internal func alc_loadPersistentStores(completionHandler block: @escaping (PersistentStoreDescription, Error?) -> Void) {
        self.loadPersistentStores(completionHandler: block)
    }
    
    internal func configureDefaults(for context: NSManagedObjectContext) {
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

}

// MARK: -

@available(iOS 10.0, *) // to make CocoaPods happy
@available(macOSApplicationExtension 10.12, iOSApplicationExtension 10.0, tvOSApplicationExtension 10.0, watchOSApplicationExtension 3.0, *)
extension NSPersistentStoreDescription: PersistentStoreDescription {
    
}
