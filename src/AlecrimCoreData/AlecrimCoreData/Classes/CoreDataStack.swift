//
//  CoreDataStack.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-24.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    let model: NSManagedObjectModel
    let coordinator: NSPersistentStoreCoordinator
    let store: NSPersistentStore
    let context: NSManagedObjectContext
    
    init(modelName name: String?) {
        let bundle = NSBundle.mainBundle()
        let modelName = (name == nil ? bundle.infoDictionary[kCFBundleNameKey] as String : name!)
        let modelURL = bundle.URLForResource(modelName, withExtension: "momd")
        
        let fileManager = NSFileManager.defaultManager()
        let urls = fileManager.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
        let applicationSupportDirectoryURL = urls[urls.endIndex - 1] as NSURL

        let localStoreDirectoryURL = applicationSupportDirectoryURL.URLByAppendingPathComponent(bundle.bundleIdentifier, isDirectory: true)
        if !fileManager.fileExistsAtPath(localStoreDirectoryURL.absoluteString) {
            fileManager.createDirectoryAtURL(localStoreDirectoryURL, withIntermediateDirectories: true, attributes: nil, error: nil)
        }

        let storeFilename = modelName.stringByAppendingPathExtension("sqlite")
        let localStoreFileURL = localStoreDirectoryURL.URLByAppendingPathComponent(storeFilename, isDirectory: false)
        
        self.model = NSManagedObjectModel(contentsOfURL: modelURL)
        self.coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model)
        self.store = self.coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: localStoreFileURL, options: nil, error: nil)
        
        self.context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        self.context.persistentStoreCoordinator = self.coordinator
        self.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
