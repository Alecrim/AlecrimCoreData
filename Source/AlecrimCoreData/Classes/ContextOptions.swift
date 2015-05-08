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

    // MARK: - public static properties
    public static var stringComparisonPredicateOptions = (NSComparisonPredicateOptions.CaseInsensitivePredicateOption | NSComparisonPredicateOptions.DiacriticInsensitivePredicateOption)

    // MARK: - public properties - fetch request
    public var fetchBatchSize = 20
    
    // MARK: - public properties - entity class names x entity names
    public var entityClassNamePrefix: String? = nil                     // you will have to change this if your class names begin with prefixes (for example: DMCustomer)
    public var entityClassNameSuffix: String? = nil                     // you will have to change this if your class names have suffixes (for example: CustomerEntity)
    
    // MARK: - public properties - stack options
    public let stackType: StackType
    public var configuration: String? = nil

    // MARK: - public properties - store options
    public var storeOptions: [NSObject : AnyObject]!
    public var migratePersistentStoresAutomatically = true
    public var inferMappingModelAutomaticallyOption = true

    // MARK: - public properties - bundles
    public let mainBundle: NSBundle = NSBundle.mainBundle()
    public var modelBundle: NSBundle = NSBundle.mainBundle()            // you will have to change this if your xcdatamodeld file is not in the main bundle (in a framework bundle, for example)
    
    // MARK: - public properties - managed object model
    public var managedObjectModelName: String!                          // defaults to main bundle name
    public private(set) var managedObjectModelURL: NSURL! = nil
    public private(set) var managedObjectModel: NSManagedObjectModel! = nil

    // MARK: - public peroprties - app extensions
    public var securityApplicationGroupIdentifier: String?              // intented for app extensions use (com.apple.security.application-groups entitlement needed)

    // MARK: - public properties - persistent location
    public var persistentStoreRelativePath: String! = nil               // defaults to main bundle identifier
    public var persistentStoreFileName: String! = nil                   // defaults to managed object model name + ".sqlite"
    public private(set) var persistentStoreURL: NSURL! = nil

    // MARK: - public properties - iCloud
    public var ubiquityEnabled = false                                  // turns the iCloud "light" on/off
    public var ubiquitousContainerIdentifier: String!                   // defaults to "iCloud." + main bundle identifier
    public var ubiquitousContentName = "UbiquityStore"
    public var ubiquitousContentRelativePath: String! = "CoreData/TransactionLogs"
    public private(set) var ubiquitousContentURL: NSURL! = nil

    // MARK: - private / internal properties
    internal private(set) var filled = false
    private var cachedEntityNames = Dictionary<String, String>()
    
    // MARK: - init (finally)
    public init(stackType: StackType = StackType.SQLite, managedObjectModelName: String? = nil, storeOptions: [NSObject : AnyObject]? = nil) {
        self.stackType = stackType
        self.managedObjectModelName = managedObjectModelName
        self.storeOptions = storeOptions
    }
    
}

extension ContextOptions {
    
    internal func fillEmptyOptions(customConfiguration: Bool = false) {
        //
        if self.filled {
            return
        }
        
        // verify if we have exiting managed object contexts set (customConfiguration == true in this case)
        if customConfiguration {
            self.filled = true
            return
        }
        
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
            if self.persistentStoreRelativePath == nil {
                self.persistentStoreRelativePath = bundleIdentifier
            }
            
            let fileManager = NSFileManager.defaultManager()
            let persistentStoreContainerURL: NSURL?
            
            if let securityApplicationGroupIdentifier = self.securityApplicationGroupIdentifier {
                // stored in "~/Library/Group Containers/." (this method also creates the directory if it does not yet exist)
                persistentStoreContainerURL = fileManager.containerURLForSecurityApplicationGroupIdentifier(securityApplicationGroupIdentifier)
            } else{
                let urls = fileManager.URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask)
                persistentStoreContainerURL = urls.last as? NSURL
            }
            
            if let containerURL = persistentStoreContainerURL {
                if self.persistentStoreFileName == nil {
                    self.persistentStoreFileName = self.managedObjectModelName.stringByAppendingPathExtension("sqlite")!
                }
                
                let persistentStoreDirectoryURL = containerURL.URLByAppendingPathComponent(self.persistentStoreRelativePath, isDirectory: true)
                self.persistentStoreURL = persistentStoreDirectoryURL.URLByAppendingPathComponent(self.persistentStoreFileName, isDirectory: false)
                
                if !fileManager.fileExistsAtPath(persistentStoreDirectoryURL.path!) {
                    fileManager.createDirectoryAtURL(persistentStoreDirectoryURL, withIntermediateDirectories: true, attributes: nil, error: nil)
                }
            }
        }
        
        // iCloud
        if self.ubiquityEnabled {
            if self.ubiquitousContainerIdentifier == nil {
                if let bundleIdentifier = self.mainBundle.bundleIdentifier {
                    self.ubiquitousContainerIdentifier = NSString(format: "%@.%@", "iCloud", bundleIdentifier) as String
                }
            }
            
            if self.ubiquitousContainerIdentifier != nil {
                if var ubiquitousContentURL = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(self.ubiquitousContainerIdentifier) {
                    if let ubiquitousContentRelativePath = self.ubiquitousContentRelativePath {
                        ubiquitousContentURL = ubiquitousContentURL.URLByAppendingPathComponent(ubiquitousContentRelativePath, isDirectory: true)
                    }
                    
                    self.ubiquitousContentURL = ubiquitousContentURL
                }
            }
            
            if self.ubiquitousContentURL == nil  {
                self.ubiquityEnabled = false
            }
        }
        
        // store options
        if self.storeOptions == nil {
            self.storeOptions = [NSObject : AnyObject]()
        }
        
        //
        self.filled = true
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
