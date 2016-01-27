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
    
    //
    internal lazy var delegate = FetchRequestControllerDelegate<T>()
    
    //
    private lazy var underlyingFetchedResultsController: NSFetchedResultsController = {
        let frc = NSFetchedResultsController(fetchRequest: self.fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: self.sectionNameKeyPath, cacheName: self.cacheName)
        frc.delegate = self.delegate
        
        return frc
    }()

    //
    private let initialPredicate: NSPredicate?
    private let initialSortDescriptors: [NSSortDescriptor]?
    
    /// Returns a fetch request controller initialized using the given arguments.
    ///
    /// - parameter fetchRequest:         The fetch request used to get the entities.
    /// - parameter managedObjectContext: The managed object against which *fetchRequest* is executed.
    /// - parameter sectionNameKeyPath:   A key path on result objects that returns the section name. Pass `nil` to indicate that the controller should generate a single section.
    /// - parameter cacheName:            The name of the cache file the receiver should use. Pass `nil` to prevent caching.
    ///
    /// - returns: The receiver initialized with the specified fetch request, context, section name key path, and cache name.
    ///
    /// - warning: Unlike the previous versions of **AlecrimCoreData** the fetch request is NOT executed until
    ///            a call to `performFetch:` method is made. This is the same behavior found in `NSFetchedResultsController`.
    private init(fetchRequest: NSFetchRequest, managedObjectContext: NSManagedObjectContext, sectionNameKeyPath: String? = nil, cacheName: String? = nil) {
        //
        self.fetchRequest = fetchRequest
        self.managedObjectContext = managedObjectContext
        self.sectionNameKeyPath = sectionNameKeyPath
        self.cacheName = cacheName
        
        //
        self.initialPredicate = fetchRequest.predicate?.copy() as? NSPredicate
        self.initialSortDescriptors = fetchRequest.sortDescriptors
    }

    /// Returns a fetch request controller initialized using the given arguments.
    ///
    /// - parameter table:              A `Table` instance from where the fetch request and managed object context will be provided.
    /// - parameter sectionNameKeyPath: A key path on result objects that returns the section name. Pass `nil` to indicate that the controller should generate a single section.
    /// - parameter cacheName:          The name of the cache file the receiver should use. Pass `nil` to prevent caching.
    ///
    /// - returns: The receiver initialized with the specified `Table` fetch request and context, the section name key path and cache name.
    ///
    /// - warning: Unlike the previous versions of **AlecrimCoreData** the fetch request is NOT executed until
    ///            a call to `performFetch:` method is made. This is the same behavior found in `NSFetchedResultsController`.
    private convenience init<T: TableType>(table: T, sectionNameKeyPath: String? = nil, cacheName: String? = nil) {
        self.init(fetchRequest: table.toFetchRequest(), managedObjectContext: table.dataContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
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

// MARK: - Reloading Data

extension FetchRequestController {
    
    public func refreshWithPredicate(predicate: NSPredicate?, keepOriginalPredicate: Bool = false) throws {
        self.assignPredicate(predicate, keepOriginalPredicate: keepOriginalPredicate)
        
        try self.refresh()
    }
    
    public func refreshWithSortDescriptors(sortDescriptors: [NSSortDescriptor]?, keepOriginalSortDescriptors: Bool = false) throws {
        self.assignSortDescriptors(sortDescriptors, keepOriginalSortDescriptors: keepOriginalSortDescriptors)
        
        try self.refresh()
    }
    
    public func refreshWithPredicate(predicate: NSPredicate?, andSortDescriptors sortDescriptors: [NSSortDescriptor]?, keepOriginalPredicate: Bool = true, keepOriginalSortDescriptors: Bool = true) throws {
        self.assignPredicate(predicate, keepOriginalPredicate: keepOriginalPredicate)
        self.assignSortDescriptors(sortDescriptors, keepOriginalSortDescriptors: keepOriginalSortDescriptors)
        
        try self.refresh()
    }
    
    public func resetPredicate() throws {
        try self.refreshWithPredicate(self.initialPredicate, keepOriginalPredicate: false)
    }
    
    public func resetSortDescriptors() throws {
        try self.refreshWithSortDescriptors(self.initialSortDescriptors, keepOriginalSortDescriptors: false)
    }
    
    public func resetPredicateAndSortDescriptors() throws {
        try self.refreshWithPredicate(self.initialPredicate, andSortDescriptors: self.initialSortDescriptors, keepOriginalPredicate: false, keepOriginalSortDescriptors: false)
    }
    
}

extension FetchRequestController {
    
    public func filter(predicateClosure: (T.Type) -> NSPredicate) throws {
        let predicate = predicateClosure(T.self)
        try self.refreshWithPredicate(predicate, keepOriginalPredicate: true)
    }
    
    public func resetFilter() throws {
        try self.resetPredicate()
    }
    
    public func reset() throws {
        try self.resetPredicateAndSortDescriptors()
    }
    
}

extension FetchRequestController {
 
    private func assignPredicate(predicate: NSPredicate?, keepOriginalPredicate: Bool) {
        let newPredicate: NSPredicate?
        
        if keepOriginalPredicate {
            if let initialPredicate = self.initialPredicate {
                if let predicate = predicate {
                    newPredicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [initialPredicate, predicate])
                }
                else {
                    newPredicate = initialPredicate
                }
            }
            else {
                newPredicate = predicate
            }
        }
        else {
            newPredicate = predicate
        }
        
        self.fetchRequest.predicate = newPredicate
    }
    
    private func assignSortDescriptors(sortDescriptors: [NSSortDescriptor]?, keepOriginalSortDescriptors: Bool) {
        let newSortDescriptors: [NSSortDescriptor]?
        
        if keepOriginalSortDescriptors {
            if let initialSortDescriptors = self.initialSortDescriptors {
                if let sortDescriptors = sortDescriptors {
                    var tempSortDescriptors = initialSortDescriptors
                    tempSortDescriptors += sortDescriptors
                    
                    newSortDescriptors = tempSortDescriptors
                }
                else {
                    newSortDescriptors = initialSortDescriptors
                }
            }
            else {
                newSortDescriptors = sortDescriptors
            }
        }
        else {
            newSortDescriptors = sortDescriptors
        }
        
        self.fetchRequest.sortDescriptors = newSortDescriptors
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
    
    internal init(underlyingSectionInfo: NSFetchedResultsSectionInfo) {
        self.underlyingSectionInfo = underlyingSectionInfo
    }
    
}

// MARK: - TableType extensions

extension TableType {
    
    /// Returns a fetch request controller initialized using the given arguments.
    ///
    /// - parameter sectionNameKeyPath: A key path on result entities that returns the section name. Pass `nil` to indicate that the controller should generate a single section.
    /// - parameter cacheName:          The name of the cache file the receiver should use. Pass `nil` to prevent caching.
    ///
    /// - returns: The initialized fetch request controller from `Table` with the specified section name key path and cache name.
    ///
    /// - warning: Unlike the previous versions of **AlecrimCoreData** the fetch request is NOT executed until
    ///            a call to `performFetch:` method is made. This is the same behavior found in `NSFetchedResultsController`.
    public func toFetchRequestController(sectionNameKeyPath sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> FetchRequestController<Self.Item> {
        return FetchRequestController(table: self, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }
    
    /// Returns a fetch request controller initialized using the given arguments.
    ///
    /// - parameter sectionAttributeClosure: A closure returning an `Attribute` that will provide the `sectionNameKeyPath` value.
    ///
    /// - returns: The initialized fetch request controller from `Table` with the specified section name key path and cache name.
    ///
    /// - warning: Unlike the previous versions of **AlecrimCoreData** the fetch request is NOT executed until
    ///            a call to `performFetch:` method is made. This is the same behavior found in `NSFetchedResultsController`.
    public func toFetchRequestController<A>(@noescape sectionAttributeClosure: (Self.Item.Type) -> Attribute<A>) -> FetchRequestController<Self.Item> {
        return FetchRequestController(table: self, sectionNameKeyPath: sectionAttributeClosure(Self.Item.self).___name)
    }
    
    // MARK: -
    
    @available(*, unavailable, renamed="toFetchRequestController")
    public func toFetchedResultsController(sectionNameKeyPath sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> FetchRequestController<Self.Item> {
        return FetchRequestController(table: self, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

    @available(*, unavailable, renamed="toFetchRequestController")
    public func toFetchedResultsController<A>(@noescape sectionAttributeClosure: (Self.Item.Type) -> Attribute<A>) -> FetchRequestController<Self.Item> {
        return FetchRequestController(table: self, sectionNameKeyPath: sectionAttributeClosure(Self.Item.self).___name)
    }

}


// MARK: - 

@available(*, unavailable, renamed="FetchRequestController")
public final class FetchedResultsController<T: NSManagedObject> {
    
}

@available(*, unavailable, renamed="FetchRequestControllerSection")
public struct FetchedResultsControllerSectionInfo<T: NSManagedObject> {
    
}
