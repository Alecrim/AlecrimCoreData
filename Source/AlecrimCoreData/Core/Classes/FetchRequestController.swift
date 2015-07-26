//
//  FetchRequestController.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-08-09.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

/// A strongly typed `NSFetchedResultsController` wrapper.
public final class FetchRequestController<T: NSManagedObject> {
    
    /// The fetch request used to do the fetching.
    public let fetchRequest: NSFetchRequest
    
    /// The managed object context used to fetch objects.
    ///
    /// - discussion: The controller registers to listen to change notifications on this context and properly update its result set and section information.
    public let managedObjectContext: NSManagedObjectContext

    /// The key path on the fetched entities used to determine the section they belong to.
    public let sectionNameKeyPath: String?
    
    /// The name of the file used to cache section information.
    public let cacheName: String?
    
    private lazy var underlyingFetchedResultsController: NSFetchedResultsController = {
        return NSFetchedResultsController(fetchRequest: self.fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: self.sectionNameKeyPath, cacheName: self.cacheName)
    }()
    
    /// Returns a fetch request controller initialized using the given arguments.
    ///
    /// - parameter fetchRequest:         The fetch request used to get the entities.
    /// - parameter managedObjectContext: The managed object against which *fetchRequest* is executed.
    /// - parameter sectionNameKeyPath:   A key path on result objects that returns the section name. Pass `nil` to indicate that the controller should generate a single section.
    /// - parameter cacheName:            The name of the cache file the receiver should use. Pass `nil` to prevent caching.
    ///
    /// - returns: The receiver initialized with the specified fetch request, context, key path, and cache name.
    ///
    /// - warning: Unlike the previous versions of **AlecrimCoreData** the fetch request is NOT executed until
    ///            a call to `performFetch:` method is made. This is the same behavior `NSFetchedResultsController` has.
    public init(fetchRequest: NSFetchRequest, managedObjectContext: NSManagedObjectContext, sectionNameKeyPath: String? = nil, cacheName: String? = nil) {
        self.fetchRequest = fetchRequest
        self.managedObjectContext = managedObjectContext
        self.sectionNameKeyPath = sectionNameKeyPath
        self.cacheName = cacheName
    }
    
}

// MARK: - Initialization

extension FetchRequestController {
    
    /// Executes the receiver’s fetch request.
    public func performFetch() throws {
        try self.underlyingFetchedResultsController.performFetch()
    }
    
}

// MARK: - Configuration Information

extension FetchRequestController {
    
    /// Deletes the cached section information with the given name.
    ///
    /// - parameter name: The name of the cache file to delete.
    ///
    /// If *name* is `nil`, deletes all cache files.
    public class func deleteCacheWithName(name: String?) {
        NSFetchedResultsController.deleteCacheWithName(name)
    }
    
}

// MARK: - Accessing Results

extension FetchRequestController {

    /// The results of the fetch.
    public var fetchedEntities: [T]? {
        return self.underlyingFetchedResultsController.fetchedObjects as? [T]
    }
    
    /// Returns the entity at the given index path in the fetch results.
    ///
    /// - parameter indexPath: An index path in the fetch results.
    ///
    /// - returns: The entity at a given index path in the fetch results.
    public func entityAtIndexPath(indexPath: NSIndexPath) -> T {
        return self.underlyingFetchedResultsController.objectAtIndexPath(indexPath) as! T
    }

    /// Returns the index path of a given entity.
    ///
    /// - parameter entity: An entity in the receiver’s fetch results.
    ///
    /// - returns: The index path of *entity* in the receiver’s fetch results, or `nil` if *entity* could not be found.
    public func indexPathForEntity(entity: T) -> NSIndexPath? {
        return self.underlyingFetchedResultsController.indexPathForObject(entity)
    }

}

// MARK: - Querying Section Information

extension FetchRequestController {
    
    /// The sections for the receiver’s fetch results.
    public var sections: [FetchRequestControllerSection<T>]? {
        return self.underlyingFetchedResultsController.sections?.map { FetchRequestControllerSection<T>(underlyingSectionInfo: $0) }
    }
    
    /// Returns the section number for a given section title and index in the section index.
    ///
    /// - parameter title:        The title of a section.
    /// - parameter sectionIndex: The index of a section.
    ///
    /// - returns: The section number for the given section title and index in the section index.
    public func sectionForSectionIndexTitle(title: String, atIndex sectionIndex: Int) -> Int {
        return self.underlyingFetchedResultsController.sectionForSectionIndexTitle(title, atIndex: sectionIndex)
    }
    
}

// MARK: - Configuring Section Information

extension FetchRequestController {
    
    /// Returns the corresponding section index entry for a given section name.
    ///
    /// - parameter sectionName: The name of a section.
    ///
    /// - returns: The section index entry corresponding to the section with name *sectionName*.
    public func sectionIndexTitleForSectionName(sectionName: String) -> String? {
        return self.underlyingFetchedResultsController.sectionIndexTitleForSectionName(sectionName)
    }

    /// The array of section index titles.
    public var sectionIndexTitles: [String] {
        return self.underlyingFetchedResultsController.sectionIndexTitles
    }

}

// MARK: - FetchRequestControllerSection

/// A strongly typed `NSFetchedResultsSectionInfo` wrapper.
public struct FetchRequestControllerSection<T: NSManagedObject> {
    
    private let underlyingSectionInfo: NSFetchedResultsSectionInfo
    
    /// The name of the section.
    public var name: String? { return self.underlyingSectionInfo.name }
    
    /// The index title of the section.
    public var indexTitle: String? { return self.underlyingSectionInfo.indexTitle }
    
    /// The number of entities (rows) in the section.
    public var numberOfEntities: Int { return self.underlyingSectionInfo.numberOfObjects }
    
    /// The array of entities in the section.
    public var entities: [T]? { return self.underlyingSectionInfo.objects as? [T] }
    
    private init(underlyingSectionInfo: NSFetchedResultsSectionInfo) {
        self.underlyingSectionInfo = underlyingSectionInfo
    }
    
}

// MARK: - Table extensions

extension Table {
    
    /// Returns a fetch request controller initialized using the given arguments.
    ///
    /// - parameter sectionNameKeyPath: A key path on result entities that returns the section name. Pass `nil` to indicate that the controller should generate a single section.
    /// - parameter cacheName:          The name of the cache file the receiver should use. Pass `nil` to prevent caching.
    ///
    /// - returns: The initialized fetch request controller from `Table` with the specified section name key path and cache name.
    public func toFetchRequestController(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> FetchRequestController<T> {
        return FetchRequestController<T>(fetchRequest: self.toFetchRequest(), managedObjectContext: self.dataContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }
    
    /// Returns a fetch request controller initialized using the given arguments.
    ///
    /// - parameter sectionAttributeClosure: A closure returning an `Attribute` that will provide the `sectionNameKeyPath` value.
    ///
    /// - returns: The initialized fetch request controller from `Table` with the specified section name key path and cache name.
    public func toFetchRequestController<A>(@noescape sectionAttributeClosure: (T.Type) -> Attribute<A>) -> FetchRequestController<T> {
        return FetchRequestController<T>(fetchRequest: self.toFetchRequest(), managedObjectContext: self.dataContext, sectionNameKeyPath: sectionAttributeClosure(T.self).___name)
    }
    
}
