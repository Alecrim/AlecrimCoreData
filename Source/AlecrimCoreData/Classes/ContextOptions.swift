//
//  ContextOptions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-02-26.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public final class ContextOptions {
    
    internal static var cachedEntityNames = Dictionary<String, String>()
    public static var fetchBatchSize = 20
    public static var stringComparisonPredicateOptions = (NSComparisonPredicateOptions.CaseInsensitivePredicateOption | NSComparisonPredicateOptions.DiacriticInsensitivePredicateOption)
    public static var entityClassNamePrefix: String? = nil
    public static var entityClassNameSuffix: String? = nil

    public let mainBundle: NSBundle = NSBundle.mainBundle()
    public var modelBundle: NSBundle = NSBundle.mainBundle()

    public var managedObjectModelName: String! = nil    // defaults to main bundle name
    private(set) public var managedObjectModelURL: NSURL! = nil
    private(set) public var managedObjectModel: NSManagedObjectModel! = nil
    
    private(set) public var localStoreFileURL: NSURL! = nil
    public var localStoreRelativePath: String! = nil    // defaults to main bundle identifier
    public var localStoreFileName: String! = nil        // defaults to managed object model name + ".sqlite"

    public var stackType = StackType.SQLite

    public var configuration: String? = nil
    
    public var ubiquityEnabled = false
    public var ubiquitousContentName = "UbiquityStore"
    public var ubiquitousContentRelativePath = "Data/TransactionLogs"
    
    public var migratePersistentStoresAutomatically = true
    public var inferMappingModelAutomaticallyOption = true
    
    public var storeOptions: [NSObject : AnyObject]? = nil
    
}

extension ContextOptions {
    
    internal func fillEmptyOptions() {
        // if managed object model name is nil, try to get default name from main bundle
        if self.managedObjectModelName == nil {
            if let infoDictionary = self.mainBundle.infoDictionary {
                self.managedObjectModelName = infoDictionary[kCFBundleNameKey] as? String
            }
        }

        // managed object model
        if self.managedObjectModelName != nil {
            self.managedObjectModelURL = self.modelBundle.URLForResource(self.managedObjectModelName!, withExtension: "momd")
            
            if self.managedObjectModelURL != nil {
                self.managedObjectModel = NSManagedObjectModel(contentsOfURL: self.managedObjectModelURL)
            }
        }
        
        // local store
        if let bundleIdentifier = self.mainBundle.bundleIdentifier {
            if self.localStoreRelativePath == nil {
                self.localStoreRelativePath = bundleIdentifier
            }
            
            let fileManager = NSFileManager.defaultManager()
            let urls = fileManager.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
            
            if let applicationSupportDirectoryURL = urls.last as? NSURL {
                if self.localStoreFileName == nil {
                    self.localStoreFileName = self.managedObjectModelName.stringByAppendingPathExtension("sqlite")!
                }
                
                let localStoreURL = applicationSupportDirectoryURL.URLByAppendingPathComponent(self.localStoreRelativePath, isDirectory: true)

                self.localStoreFileURL = localStoreURL.URLByAppendingPathComponent(self.localStoreFileName, isDirectory: false)
                
                if let localStorePath = localStoreURL.path {
                    let fileManager = NSFileManager.defaultManager()

                    if !fileManager.fileExistsAtPath(localStorePath) {
                        fileManager.createDirectoryAtURL(localStoreURL, withIntermediateDirectories: true, attributes: nil, error: nil)
                    }
                }
            }
        }
    }
    
}