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
    
    init(name: String, managedObjectModel model: NSManagedObjectModel, contextType: NSManagedObjectContext.Type)
}

// MARK: -

open class GenericPersistentContainer<ContextType: NSManagedObjectContext> {

    // MARK: -

    open class func defaultDirectoryURL() -> URL {
        if #available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) {
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
        if let modelURL = Bundle.main.url(forResource: name, withExtension: "momd") ?? Bundle.main.url(forResource: name, withExtension: "mom") {
            if let model = NSManagedObjectModel(contentsOf: modelURL) {
                self.init(name: name, managedObjectModel: model)
                return
            }
            
            fatalError("CoreData: Failed to load model at path: \(modelURL)")
        }
        
        guard let model = NSManagedObjectModel.mergedModel(from: [Bundle.main]) else {
            fatalError("Couldn't find managed object model in main bundle.")
            
        }

        self.init(name: name, managedObjectModel: model)
    }
    
    
    public init(name: String, managedObjectModel model: NSManagedObjectModel) {
        if #available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *) {
            self.underlyingPersistentContainer = NativePersistentContainer(name: name, managedObjectModel: model, contextType: ContextType.self)
        }
        else {
            self.underlyingPersistentContainer = CustomPersistentContainer(name: name, managedObjectModel: model, contextType: ContextType.self)
        }
    }
    
    // MARK: -
    
    public func loadPersistentStores(completionHandler block: @escaping (PersistentStoreDescription, Error?) -> Void) {
        self.underlyingPersistentContainer.alc_loadPersistentStores(completionHandler: block)
    }
    
    public func newBackgroundContext() -> ContextType {
        return self.underlyingPersistentContainer.newBackgroundContext() as! ContextType
    }
    
    public func performBackgroundTask(_ block: @escaping (ContextType) -> Void) {
        let context = self.newBackgroundContext()
        
        context.perform {
            block(context)
        }
    }
    
}

