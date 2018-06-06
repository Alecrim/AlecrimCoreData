//
//  CustomPersistentContainer.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 20/05/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

open class CustomPersistentContainer<Context: NSManagedObjectContext> {

    // MARK: -

    fileprivate final class HelperPersistentContainer<Context: NSManagedObjectContext>: PersistentContainer {

        private lazy var _viewContext: NSManagedObjectContext = {
            let context = Context(concurrencyType: .mainQueueConcurrencyType)

            context.persistentStoreCoordinator = self.persistentStoreCoordinator

            context.automaticallyMergesChangesFromParent = true
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            return context
        }()

        fileprivate override var viewContext: NSManagedObjectContext { return self._viewContext }

        fileprivate override func newBackgroundContext() -> NSManagedObjectContext {
            let context = Context(concurrencyType: .privateQueueConcurrencyType)

            context.persistentStoreCoordinator = self.persistentStoreCoordinator

            context.automaticallyMergesChangesFromParent = true
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            return context
        }

        fileprivate override func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
            super.performBackgroundTask { context in
                //
                context.persistentStoreCoordinator = self.persistentStoreCoordinator

                //
                context.automaticallyMergesChangesFromParent = true
                context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

                //
                block(context)
            }
        }

    }


    // MARK: -

    fileprivate let rawValue: NSPersistentContainer

    // MARK: -

    public convenience init() {
        try! self.init(storageType: .disk, managedObjectModel: type(of: self).managedObjectModel(), persistentStoreURL: type(of: self).persistentStoreURL(), ubiquitousConfiguration: nil)
    }

    public init(storageType: PersistentContainerStorageType = .disk, managedObjectModel: NSManagedObjectModel, persistentStoreURL: URL, persistentStoreDescriptionOptions: [String : NSObject]? = nil, ubiquitousConfiguration: PersistentContainerUbiquitousConfiguration? = nil) throws {
        self.rawValue = try HelperPersistentContainer<Context>(storageType: storageType, managedObjectModel: managedObjectModel, persistentStoreURL: persistentStoreURL, persistentStoreDescriptionOptions: persistentStoreDescriptionOptions, ubiquitousConfiguration: ubiquitousConfiguration)
    }

    // MARK: -

    open var viewContext: Context {
        return unsafeDowncast(self.rawValue.viewContext, to: Context.self)
    }

    open func newBackgroundContext() -> Context {
        return unsafeDowncast(self.rawValue.newBackgroundContext(), to: Context.self)
    }

    open func performBackgroundTask(_ block: @escaping (Context) -> Void) {
        self.rawValue.performBackgroundTask { managedObjectContext in
            block(unsafeDowncast(managedObjectContext, to: Context.self))
        }
    }

}
