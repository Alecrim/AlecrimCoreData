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
    public let fetchRequest: NSFetchRequest<T>
    
    /// The managed object context used to fetch objects.
    ///
    /// - discussion: The controller registers to listen to change notifications on this context and properly update its result set and section information.
    public let managedObjectContext: NSManagedObjectContext

    /// The key path on the fetched entities used to determine the section they belong to.
    public let sectionNameKeyPath: String?
    
    /// The name of the file used to cache section information.
    public let cacheName: String?
    
    //
    internal private(set) lazy var delegate = FetchRequestControllerDelegate<T>()
    
    deinit {
        self.underlyingFetchedResultsController.delegate = nil
    }
    
    /// The underlying NSFetchedResultsController managed by this controller.
    ///
    /// - discussion: DO NOT modify properties of the underlying fetched results controller directly, it is for integration with other libraries which need to fetch data using a FRC.
    public private(set) lazy var underlyingFetchedResultsController: NSFetchedResultsController<T> = {
        let frc = NSFetchedResultsController(fetchRequest: self.fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: self.sectionNameKeyPath, cacheName: self.cacheName)
        frc.delegate = self.delegate
        
        return frc
    }()

    //
    fileprivate let initialPredicate: NSPredicate?
    fileprivate let initialSortDescriptors: [NSSortDescriptor]?
    
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
    fileprivate init(fetchRequest: NSFetchRequest<T>, managedObjectContext: NSManagedObjectContext, sectionNameKeyPath: String? = nil, cacheName: String? = nil) {
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
    fileprivate convenience init<T: TableProtocol>(table: T, sectionNameKeyPath: String? = nil, cacheName: String? = nil) {
        self.init(fetchRequest: table.toFetchRequest(), managedObjectContext: table.context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
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
    public class func deleteCache(withName name: String?) {
        NSFetchedResultsController<T>.deleteCache(withName: name)
    }

}

// MARK: - Accessing Results

extension FetchRequestController {

    /// The results of the fetch.
    public var fetchedObjects: [T]? {
        return self.underlyingFetchedResultsController.fetchedObjects
    }
    
    /// Returns the object at the given index path in the fetch results.
    ///
    /// - parameter indexPath: An index path in the fetch results.
    ///
    /// - returns: The object at a given index path in the fetch results.
    public func object(at indexPath: IndexPath) -> T {
        return self.underlyingFetchedResultsController.object(at: indexPath)
    }

    /// Returns the index path of a given object.
    ///
    /// - parameter object: An object in the receiver’s fetch results.
    ///
    /// - returns: The index path of *object* in the receiver’s fetch results, or `nil` if *object* could not be found.
    public func indexPath(for object: T) -> IndexPath? {
        return self.underlyingFetchedResultsController.indexPath(forObject: object)
    }

}

extension FetchRequestController {
    
    public func numberOfSections() -> Int {
        return self.sections.count
    }
    
    public func numberOfObjects(inSection section: Int) -> Int {
        return self.sections[section].numberOfObjects
    }
    
}

// MARK: - Querying Section Information

extension FetchRequestController {
    
    /// The sections for the receiver’s fetch results.
    public var sections: [FetchRequestControllerSection<T>] {
        guard let result = self.underlyingFetchedResultsController.sections?.map({ FetchRequestControllerSection<T>(underlyingSectionInfo: $0) }) else {
            fatalError("performFetch: hasn't been called.")
        }
        
        return result
    }
    
    /// Returns the section number for a given section title and index in the section index.
    ///
    /// - parameter title:        The title of a section.
    /// - parameter sectionIndex: The index of a section.
    ///
    /// - returns: The section number for the given section title and index in the section index.
    public func section(forSectionIndexTitle title: String, at sectionIndex: Int) -> Int {
        return self.underlyingFetchedResultsController.section(forSectionIndexTitle: title, at: sectionIndex)
    }
    
}

// MARK: - Configuring Section Information

extension FetchRequestController {
    
    /// Returns the corresponding section index entry for a given section name.
    ///
    /// - parameter sectionName: The name of a section.
    ///
    /// - returns: The section index entry corresponding to the section with name *sectionName*.
    public func sectionIndexTitle(forSectionName sectionName: String) -> String? {
        return self.underlyingFetchedResultsController.sectionIndexTitle(forSectionName: sectionName)
    }

    /// The array of section index titles.
    public var sectionIndexTitles: [String] {
        return self.underlyingFetchedResultsController.sectionIndexTitles
    }

}

// MARK: - Reloading Data

extension FetchRequestController {
    
    public func refresh(using predicate: NSPredicate?, keepOriginalPredicate: Bool) throws {
        self.assignPredicate(predicate, keepOriginalPredicate: keepOriginalPredicate)
        
        try self.refresh()
    }

    public func refresh(using sortDescriptors: [NSSortDescriptor]?, keepOriginalSortDescriptors: Bool) throws {
        self.assignSortDescriptors(sortDescriptors, keepOriginalSortDescriptors: keepOriginalSortDescriptors)
        
        try self.refresh()
    }
    
    public func refresh(using predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, keepOriginalPredicate: Bool, keepOriginalSortDescriptors: Bool) throws {
        self.assignPredicate(predicate, keepOriginalPredicate: keepOriginalPredicate)
        self.assignSortDescriptors(sortDescriptors, keepOriginalSortDescriptors: keepOriginalSortDescriptors)
        
        try self.refresh()
    }
    
    public func resetPredicate() throws {
        try self.refresh(using: self.initialPredicate, keepOriginalPredicate: false)
    }
    
    public func resetSortDescriptors() throws {
        try self.refresh(using: self.initialSortDescriptors, keepOriginalSortDescriptors: false)
    }
    
    public func resetPredicateAndSortDescriptors() throws {
        try self.refresh(using: self.initialPredicate, sortDescriptors: self.initialSortDescriptors, keepOriginalPredicate: false, keepOriginalSortDescriptors: false)
    }
    
}

extension FetchRequestController {
    
    public func filter(_ predicateClosure: (T.Type) -> NSPredicate) throws {
        let predicate = predicateClosure(T.self)
        try self.refresh(using: predicate, keepOriginalPredicate: true)
    }
    
    public func resetFilter() throws {
        try self.resetPredicate()
    }
    
    public func reset() throws {
        try self.resetPredicateAndSortDescriptors()
    }
    
}

extension FetchRequestController {
 
    fileprivate func assignPredicate(_ predicate: NSPredicate?, keepOriginalPredicate: Bool) {
        let newPredicate: NSPredicate?
        
        if keepOriginalPredicate {
            if let initialPredicate = self.initialPredicate {
                if let predicate = predicate {
                    newPredicate = NSCompoundPredicate(type: .and, subpredicates: [initialPredicate, predicate])
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
    
    fileprivate func assignSortDescriptors(_ sortDescriptors: [NSSortDescriptor]?, keepOriginalSortDescriptors: Bool) {
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
    public var name: String { return self.underlyingSectionInfo.name }
    
    /// The index title of the section.
    public var indexTitle: String? { return self.underlyingSectionInfo.indexTitle }
    
    /// The number of entities (rows) in the section.
    public var numberOfObjects: Int { return self.underlyingSectionInfo.numberOfObjects }
    
    /// The array of entities in the section.
    public var objects: [T] {
        guard let result = self.underlyingSectionInfo.objects as? [T] else {
            fatalError("performFetch: hasn't been called.")
        }
        
        return result
    }
    
    internal init(underlyingSectionInfo: NSFetchedResultsSectionInfo) {
        self.underlyingSectionInfo = underlyingSectionInfo
    }
    
}

// MARK: - TableProtocol extensions

extension TableProtocol where Self.Element: NSManagedObject {
    
    /// Returns a fetch request controller initialized using the given arguments.
    ///
    /// - parameter sectionNameKeyPath: A key path on result entities that returns the section name. Pass `nil` to indicate that the controller should generate a single section.
    /// - parameter cacheName:          The name of the cache file the receiver should use. Pass `nil` to prevent caching.
    ///
    /// - returns: The initialized fetch request controller from `Table` with the specified section name key path and cache name.
    ///
    /// - warning: Unlike the previous versions of **AlecrimCoreData** the fetch request is NOT executed until
    ///            a call to `performFetch:` method is made. This is the same behavior found in `NSFetchedResultsController`.
    public func toFetchRequestController(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> FetchRequestController<Self.Element> {
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
    public func toFetchRequestController<A>(_ sectionAttributeClosure: (Self.Element.Type) -> Attribute<A>) -> FetchRequestController<Self.Element> {
        return FetchRequestController(table: self, sectionNameKeyPath: sectionAttributeClosure(Self.Element.self).___name)
    }
    
}
