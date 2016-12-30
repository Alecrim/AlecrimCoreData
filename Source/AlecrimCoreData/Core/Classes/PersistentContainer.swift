//
//  GenericPersistentContainer.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-06-20.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// MARK: -

public struct PersistentContainerOptions {
    public static var defaultBatchSize: Int = 20
    public static var defaultComparisonPredicateOptions: NSComparisonPredicate.Options = [.caseInsensitive, .diacriticInsensitive]
}

open class PersistentContainer: GenericPersistentContainer<NSManagedObjectContext> {
    
}

// MARK: -

public protocol PersistentStoreDescription {
    var type: String { get set }
    var configuration: String? { get set }
    var url: URL? { get set }
    var options: [String : NSObject] { get }
    
    var isReadOnly: Bool { get set }
    var timeout: TimeInterval { get set }
    var sqlitePragmas: [String : NSObject] { get }
    
    var shouldAddStoreAsynchronously: Bool { get set }
    var shouldMigrateStoreAutomatically: Bool { get set }
    var shouldInferMappingModelAutomatically: Bool { get set }

    func setOption(_ option: NSObject?, forKey key: String)
    func setValue(_ value: NSObject?, forPragmaNamed name: String)
}

// MARK: -

internal protocol UnderlyingPersistentContainer: class {
    var name: String { get }
    var managedObjectModel: NSManagedObjectModel { get }
    var persistentStoreCoordinator: NSPersistentStoreCoordinator { get }
    
    var viewContext: NSManagedObjectContext { get }
    var alc_persistentStoreDescriptions: [PersistentStoreDescription] { get set }
    
    func alc_loadPersistentStores(completionHandler block: @escaping (PersistentStoreDescription, Error?) -> Void)
    func newBackgroundContext() -> NSManagedObjectContext
    
    func configureDefaults(for context: NSManagedObjectContext)
    
    init(name: String, managedObjectModel model: NSManagedObjectModel, contextType: NSManagedObjectContext.Type)
}

// MARK: -

open class GenericPersistentContainer<ContextType: NSManagedObjectContext> {

    // MARK: -

    open class func defaultDirectoryURL() -> URL {
        if #available(iOS 10.0, macOSApplicationExtension 10.12, iOSApplicationExtension 10.0, tvOSApplicationExtension 10.0, watchOSApplicationExtension 3.0, *) {
            return NativePersistentContainer.defaultDirectoryURL()
        }
        else {
            return CustomPersistentContainer.defaultDirectoryURL()
        }
    }

    // MARK: -

    private let underlyingPersistentContainer: UnderlyingPersistentContainer
    
    // MARK: -
    
    public var name: String { return self.underlyingPersistentContainer.name }
    
    public var viewContext: ContextType { return self.underlyingPersistentContainer.viewContext as! ContextType }
    
    public var managedObjectModel: NSManagedObjectModel { return self.underlyingPersistentContainer.managedObjectModel }
    
    public var persistentStoreCoordinator: NSPersistentStoreCoordinator { return self.underlyingPersistentContainer.persistentStoreCoordinator }
    
    public var persistentStoreDescriptions: [PersistentStoreDescription] {
        get {
            return self.underlyingPersistentContainer.alc_persistentStoreDescriptions
        }
        set {
            self.underlyingPersistentContainer.alc_persistentStoreDescriptions = newValue
        }
    }
    
    // MARK: -
    
    public convenience init(name: String) {
        self.init(name: name, automaticallyLoadPersistentStores: true)
    }
    
    public convenience init(name: String, automaticallyLoadPersistentStores: Bool) {
        if let modelURL = Bundle.main.url(forResource: name, withExtension: "momd") ?? Bundle.main.url(forResource: name, withExtension: "mom") {
            if let model = NSManagedObjectModel(contentsOf: modelURL) {
                self.init(name: name, managedObjectModel: model, automaticallyLoadPersistentStores: automaticallyLoadPersistentStores)
                return
            }
            
            fatalError("CoreData: Failed to load model at path: \(modelURL)")
        }
        
        guard let model = NSManagedObjectModel.mergedModel(from: [Bundle.main]) else {
            fatalError("Couldn't find managed object model in main bundle.")
            
        }

        self.init(name: name, managedObjectModel: model, automaticallyLoadPersistentStores: automaticallyLoadPersistentStores)
    }
    
    
    public init(name: String, managedObjectModel model: NSManagedObjectModel, automaticallyLoadPersistentStores: Bool) {
        //
        if #available(iOS 10.0, macOSApplicationExtension 10.12, iOSApplicationExtension 10.0, tvOSApplicationExtension 10.0, watchOSApplicationExtension 3.0, *) {
            self.underlyingPersistentContainer = NativePersistentContainer(name: name, managedObjectModel: model, contextType: ContextType.self)
        }
        else {
            self.underlyingPersistentContainer = CustomPersistentContainer(name: name, managedObjectModel: model, contextType: ContextType.self)
        }
        
        //
        self.underlyingPersistentContainer.configureDefaults(for: self.viewContext)
        
        //
        if automaticallyLoadPersistentStores {
            self.loadPersistentStores { storeDescription, error in
                guard let error = error else { return }
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                
                AlecrimCoreDataError.fatalError("Unresolved error \(error), \((error as NSError).userInfo)")
            }
        }
    }
    
    // MARK: -
    
    public func loadPersistentStores(completionHandler block: @escaping (PersistentStoreDescription, Error?) -> Void) {
        self.underlyingPersistentContainer.alc_loadPersistentStores(completionHandler: block)
    }
    
    public func newBackgroundContext() -> ContextType {
        let context = self.underlyingPersistentContainer.newBackgroundContext() as! ContextType
        self.underlyingPersistentContainer.configureDefaults(for: context)
        
        return context
    }
    
    public func performBackgroundTask(_ block: @escaping (ContextType) -> Void) {
        let context = self.newBackgroundContext()
        
        context.perform {
            block(context)
        }
    }
    
}

