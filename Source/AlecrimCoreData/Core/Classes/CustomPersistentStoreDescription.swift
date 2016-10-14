//
//  CustomPersistentStoreDescription.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-10-13.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation
import CoreData

private let NSAddStoreAsynchronouslyOption = "NSAddStoreAsynchronouslyOption"

internal class CustomPersistentStoreDescription: NSObject, NSCopying, PersistentStoreDescription {
    
    // MARK: -
    
    internal var type: String = NSSQLiteStoreType
    internal var configuration: String?
    internal var url: URL?
    
    private var _options = NSMutableDictionary()
    internal var options: [String : NSObject] { return (self._options as NSDictionary) as? [String : NSObject] ?? [:] }

    // MARK: -

    internal var isReadOnly: Bool {
        get { return (self._options[NSReadOnlyPersistentStoreOption] as? NSNumber)?.boolValue ?? false }
        set { self._options[NSReadOnlyPersistentStoreOption] = NSNumber(value: newValue) }
    }
    
    internal var timeout: TimeInterval {
        get { return self._options[NSPersistentStoreTimeoutOption] as? TimeInterval ?? 240 }
        set { self._options[NSPersistentStoreTimeoutOption] = NSNumber(value: newValue) }
    }
    
    internal var sqlitePragmas: [String : NSObject] {
        return self._options[NSSQLitePragmasOption] as? [String : NSObject] ?? [:]
    }

    // MARK: -

    internal var shouldAddStoreAsynchronously: Bool {
        get { return (self._options[NSAddStoreAsynchronouslyOption] as? NSNumber)?.boolValue ?? false }
        set { self._options[NSAddStoreAsynchronouslyOption] = NSNumber(value: newValue) }
    }
    
    internal var shouldMigrateStoreAutomatically: Bool {
        get { return (self._options[NSMigratePersistentStoresAutomaticallyOption] as? NSNumber)?.boolValue ?? true }
        set { self._options[NSMigratePersistentStoresAutomaticallyOption] = NSNumber(value: newValue) }
    }
    
    internal var shouldInferMappingModelAutomatically: Bool {
        get { return (self._options[NSInferMappingModelAutomaticallyOption] as? NSNumber)?.boolValue ?? true }
        set { self._options[NSInferMappingModelAutomaticallyOption] = NSNumber(value: newValue) }
    }

    // MARK: -
    
    private override init() {
        super.init()
    }

    internal convenience init(url: URL) {
        self.init()
        
        self.url = url
        self.shouldMigrateStoreAutomatically = true
        self.shouldInferMappingModelAutomatically = true
    }
    
    // MARK: -
    
    internal func setOption(_ option: NSObject?, forKey key: String) {
        self._options[key] = option
    }

    internal func setValue(_ value: NSObject?, forPragmaNamed name: String) {
        let mutableDictionary: NSMutableDictionary
        
        if let existingMutableDictionary = self._options[NSSQLitePragmasOption] as? NSMutableDictionary {
            mutableDictionary = existingMutableDictionary
        }
        else {
            mutableDictionary = NSMutableDictionary()
            self._options[NSSQLitePragmasOption] = mutableDictionary
        }
        
        mutableDictionary[name] = value
    }

    // MARK: -
    
    internal func copy(with zone: NSZone? = nil) -> Any {
        let c = CustomPersistentStoreDescription()
        c.type = self.type
        c.configuration = self.configuration
        c.url = self.url
        
        c._options = self._options.copy(with: zone) as! NSMutableDictionary
        
        return c
    }
    
}
