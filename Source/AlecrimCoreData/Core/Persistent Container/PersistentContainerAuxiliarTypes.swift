//
//  PersistentContainerAuxiliarTypes.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 20/05/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

public enum PersistentContainerStorageType {
    case disk
    case memory
}

public struct PersistentContainerUbiquitousConfiguration {
    public let containerIdentifier: String
    public let contentRelativePath: String
    public let contentName: String

    public init(containerIdentifier: String, contentRelativePath: String = "Data/TransactionLogs", contentName: String = "UbiquityStore") {
        self.containerIdentifier = containerIdentifier
        self.contentRelativePath = contentRelativePath
        self.contentName = contentName
    }

}

public enum PersistentContainerError: Error {
    case invalidManagedObjectModelURL
    case invalidPersistentStoreURL
    case invalidGroupContainerURL
    case applicationSupportDirectoryNotFound
    case managedObjectModelNotFound
}
