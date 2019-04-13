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

    public private(set) lazy var backgroundContext: Context = self.newBackgroundContext()

    // MARK: -

    fileprivate let rawValue: NSPersistentContainer

    // MARK: -

    /// Use caution when using this initializer.
    public init(name: String? = nil) {
        self.rawValue = HelperPersistentContainer<Context>(name: name)
    }

    public init(name: String? = nil, managedObjectModel: NSManagedObjectModel, storageType: PersistentContainerStorageType, persistentStoreURL: URL, persistentStoreDescriptionOptions: [String : NSObject]? = nil, ubiquitousConfiguration: PersistentContainerUbiquitousConfiguration? = nil) throws {
        self.rawValue = try HelperPersistentContainer<Context>(name: name, managedObjectModel: managedObjectModel, storageType: storageType, persistentStoreURL: persistentStoreURL, persistentStoreDescriptionOptions: persistentStoreDescriptionOptions, ubiquitousConfiguration: ubiquitousConfiguration)
    }

    public init(name: String, managedObjectModel: NSManagedObjectModel, persistentStoreDescription: NSPersistentStoreDescription, completionHandler: @escaping (NSPersistentContainer, NSPersistentStoreDescription, Error?) -> Void) throws {
        self.rawValue = try HelperPersistentContainer<Context>(name: name, managedObjectModel: managedObjectModel, persistentStoreDescription: persistentStoreDescription, completionHandler: completionHandler)
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

// MARK: -

extension CustomPersistentContainer {

    fileprivate final class HelperPersistentContainer<Context: NSManagedObjectContext>: PersistentContainer {

        private lazy var _viewContext: NSManagedObjectContext = {
            let context = Context(concurrencyType: .mainQueueConcurrencyType)
            self.configureManagedObjectContext(context)

            return context
        }()

        fileprivate override var viewContext: NSManagedObjectContext { return self._viewContext }

        fileprivate override func newBackgroundContext() -> NSManagedObjectContext {
            let context = Context(concurrencyType: .privateQueueConcurrencyType)
            self.configureManagedObjectContext(context)

            return context
        }

        fileprivate override func configureManagedObjectContext(_ context: NSManagedObjectContext) {
            context.persistentStoreCoordinator = self.persistentStoreCoordinator
            super.configureManagedObjectContext(context)
        }

    }

}

