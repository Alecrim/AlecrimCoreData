//
//  PersistentContainerType.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 20/05/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public protocol PersistentContainerType: AnyObject {}

extension PersistentContainer: PersistentContainerType {}
extension CustomPersistentContainer: PersistentContainerType {}

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

    public static func persistentStoreURL(withName name: String? = nil, in bundle: Bundle? = nil) throws -> URL {
        guard let applicationSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last else {
            throw PersistentContainerError.applicationSupportDirectoryNotFound
        }

        let bundle = bundle ?? Bundle.main
        let bundleLastPathComponent = bundle.bundleURL.deletingPathExtension().lastPathComponent
        let name = name ?? bundleLastPathComponent

        let persistentStoreURL = applicationSupportURL
            .appendingPathComponent(bundleLastPathComponent, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent(name, isDirectory: false)
            .appendingPathExtension("sqlite")

        return persistentStoreURL
    }

    public static func persistentStoreURL(withName name: String? = nil, forSecurityApplicationGroupIdentifier applicationGroupIdentifier: String, in bundle: Bundle? = nil) throws -> URL {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: applicationGroupIdentifier) else {
            throw PersistentContainerError.invalidGroupContainerURL
        }

        let bundle = bundle ?? Bundle.main
        let bundleLastPathComponent = bundle.bundleURL.deletingPathExtension().lastPathComponent
        let name = name ?? bundleLastPathComponent

        let persistentStoreURL = containerURL
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent(bundleLastPathComponent, isDirectory: true)
            .appendingPathComponent("CoreData", isDirectory: true)
            .appendingPathComponent(name, isDirectory: false)
            .appendingPathExtension("sqlite")

        return persistentStoreURL
    }

}
