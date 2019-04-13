//
//  PersistentContainerType.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 20/05/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// MARK: -

public protocol PersistentContainerType: AnyObject {
    associatedtype ManagedObjectContextType: ManagedObjectContext

    var viewContext: ManagedObjectContextType { get }
    var backgroundContext: ManagedObjectContextType { get }
}

extension PersistentContainer: PersistentContainerType {}
extension CustomPersistentContainer: PersistentContainerType {}

// MARK: - helper static methods

extension PersistentContainerType {

    public static func managedObjectModel(withName name: String? = nil, in bundle: Bundle? = nil) throws -> NSManagedObjectModel {
        let bundle = bundle ?? Bundle(for: Self.self)
        let name = name ?? bundle.bundleURL.deletingPathExtension().lastPathComponent

        let managedObjectModelURL = try self.managedObjectModelURL(withName: name, in: bundle)

        guard let managedObjectModel = NSManagedObjectModel(contentsOf: managedObjectModelURL) else {
            throw PersistentContainerError.managedObjectModelNotFound
        }

        return managedObjectModel
    }

    private static func managedObjectModelURL(withName name: String, in bundle: Bundle) throws -> URL {
        let resourceURL = bundle.url(forResource: name, withExtension: "momd") ?? bundle.url(forResource: name, withExtension: "mom")

        guard let managedObjectModelURL = resourceURL else {
            throw PersistentContainerError.invalidManagedObjectModelURL
        }

        return managedObjectModelURL
    }

}

extension PersistentContainerType {

    public static func persistentStoreURL(withName name: String? = nil, inPath path: String? = nil) throws -> URL {
        guard let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else {
            throw PersistentContainerError.applicationSupportDirectoryNotFound
        }

        let name = name ?? Bundle.main.bundleURL.deletingPathExtension().lastPathComponent
        let path = path ?? name

        let persistentStoreURL = applicationSupportURL
            .appendingPathComponent(path, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent(name, isDirectory: false)
            .appendingPathExtension("sqlite")

        return persistentStoreURL
    }

    public static func persistentStoreURL(withName name: String, inPath path: String? = nil, forSecurityApplicationGroupIdentifier applicationGroupIdentifier: String) throws -> URL {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: applicationGroupIdentifier) else {
            throw PersistentContainerError.invalidGroupContainerURL
        }

        let path = path ?? name

        let persistentStoreURL = containerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(path, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent(name, isDirectory: false)
            .appendingPathExtension("sqlite")

        return persistentStoreURL
    }

}

