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
    
    private var cachedEntityNames = Dictionary<String, String>()

    public static var stringComparisonPredicateOptions = (NSComparisonPredicateOptions.CaseInsensitivePredicateOption | NSComparisonPredicateOptions.DiacriticInsensitivePredicateOption)
    
    public var fetchBatchSize = 20
    public var entityClassNamePrefix: String? = nil
    public var entityClassNameSuffix: String? = nil

    public let mainBundle: NSBundle = NSBundle.mainBundle()
    public var modelBundle: NSBundle = NSBundle.mainBundle()

    private(set) public var managedObjectModelURL: NSURL! = nil
    private(set) public var managedObjectModel: NSManagedObjectModel! = nil
    
    private(set) public var persistentStoreURL: NSURL! = nil
    public var pesistentStoreRelativePath: String! = nil    // defaults to main bundle identifier
    public var pesistentStoreFileName: String! = nil        // defaults to managed object model name + ".sqlite"

    public var configuration: String? = nil
    
    public var ubiquityEnabled = false
    public var ubiquitousContentName = "UbiquityStore"
    public var ubiquitousContentRelativePath = "Data/TransactionLogs"
    
    public var migratePersistentStoresAutomatically = true
    public var inferMappingModelAutomaticallyOption = true
    
    public let stackType: StackType
    private(set) public var managedObjectModelName: String!          // defaults to main bundle name
    internal(set) public var storeOptions: [NSObject : AnyObject]!
    
    public init(stackType: StackType = StackType.SQLite, managedObjectModelName: String? = nil, storeOptions: [NSObject : AnyObject]? = nil) {
        self.stackType = stackType
        self.managedObjectModelName = managedObjectModelName
        self.storeOptions = storeOptions
    }
    
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
            if self.pesistentStoreRelativePath == nil {
                self.pesistentStoreRelativePath = bundleIdentifier
            }
            
            let fileManager = NSFileManager.defaultManager()
            let urls = fileManager.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
            
            if let applicationSupportDirectoryURL = urls.last as? NSURL {
                if self.pesistentStoreFileName == nil {
                    self.pesistentStoreFileName = self.managedObjectModelName.stringByAppendingPathExtension("sqlite")!
                }
                
                let pesistentStoreDirectoryURL = applicationSupportDirectoryURL.URLByAppendingPathComponent(self.pesistentStoreRelativePath, isDirectory: true)
                self.persistentStoreURL = pesistentStoreDirectoryURL.URLByAppendingPathComponent(self.pesistentStoreFileName, isDirectory: false)
                
                let fileManager = NSFileManager.defaultManager()
                if !fileManager.fileExistsAtPath(pesistentStoreDirectoryURL.path!) {
                    fileManager.createDirectoryAtURL(pesistentStoreDirectoryURL, withIntermediateDirectories: true, attributes: nil, error: nil)
                }
            }
        }
    }
    
}

// MARK: entity class names x entity names

extension ContextOptions {
    
    internal func entityNameFromClass(aClass: AnyClass) -> String {
        let className = NSStringFromClass(aClass)
        
        if let name = self.cachedEntityNames[className] {
            return name
        }
        else {
            var name: NSString = className
            let range = name.rangeOfString(".", options: (.BackwardsSearch))
            if range.location != NSNotFound {
                name = name.substringFromIndex(range.location + 1)
            }
            
            if let prefix = self.entityClassNamePrefix {
                if !name.isEqualToString(prefix) && name.hasPrefix(prefix) {
                    name = name.substringFromIndex((prefix as NSString).length)
                }
            }
            
            if let suffix = self.entityClassNameSuffix {
                if !name.isEqualToString(suffix) && name.hasSuffix(suffix) {
                    name = name.substringToIndex(name.length - (suffix as NSString).length)
                }
            }
            
            let nameAsString = name as! String
            self.cachedEntityNames[className] = nameAsString
            
            return nameAsString
        }
    }
    
}
