//
//  FetchRequestController.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 11/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

//
// we cannot inherit from `NSFetchedResultsController` here because the error:
// "inheritance from a generic Objective-C class 'NSFetchedResultsController' must bind type parameters of
// 'NSFetchedResultsController' to specific concrete types"
// and
// `FetchRequestController<Entity: ManagedObject>: NSFetchedResultsController<NSFetchRequestResult>` will not work for us
// (curiously the "rawValue" inside our class is accepted to be `NSFetchedResultsController<Entity>`)
//

// MARK: -

public final class FetchRequestController<Entity: ManagedObject> {

    public let rawValue: NSFetchedResultsController<Entity>
    internal let rawValueDelegate: FetchedResultsControllerDelegate<Entity>
    
    fileprivate let initialPredicate: Predicate<Entity>?
    fileprivate let initialSortDescriptors: [SortDescriptor<Entity>]?

    private var didPerformFetch = false

    // MARK: -

    public convenience init<Value>(query: Query<Entity>, sectionName sectionNameKeyPathClosure: @autoclosure () -> KeyPath<Entity, Value>, cacheName: String? = nil) {
        let sectionNameKeyPath = sectionNameKeyPathClosure().pathString
        self.init(fetchRequest: query.fetchRequest, context: query.context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

    public convenience init(query: Query<Entity>, sectionNameKeyPath: String? = nil, cacheName: String? = nil) {
        self.init(fetchRequest: query.fetchRequest, context: query.context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

    public convenience init<Value>(fetchRequest: FetchRequest<Entity>, context: ManagedObjectContext, sectionName sectionNameKeyPathClosure: @autoclosure () -> KeyPath<Entity, Value>, cacheName: String? = nil) {
        let sectionNameKeyPath = sectionNameKeyPathClosure().pathString
        self.init(fetchRequest: fetchRequest, context: context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

    public init(fetchRequest: FetchRequest<Entity>, context: ManagedObjectContext, sectionNameKeyPath: String? = nil, cacheName: String? = nil) {
        self.rawValue = NSFetchedResultsController(fetchRequest: fetchRequest.toRaw() as NSFetchRequest<Entity>, managedObjectContext: context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
        self.rawValueDelegate = FetchedResultsControllerDelegate<Entity>()

        self.initialPredicate = fetchRequest.predicate
        self.initialSortDescriptors = fetchRequest.sortDescriptors

        //
        self.rawValue.delegate = self.rawValueDelegate
    }

    // MARK: -

    public func performFetch() {
        try! self.rawValue.performFetch()
        self.didPerformFetch = true
    }

    public func performFetchIfNeeded() {
        if !self.didPerformFetch {
            try! self.rawValue.performFetch()
            self.didPerformFetch = true
        }
    }

}

// MARK: -

extension FetchRequestController {
    
    public var fetchedObjects: [Entity]? {
        self.performFetchIfNeeded()
        return self.rawValue.fetchedObjects
    }
    
    public func object(at indexPath: IndexPath) -> Entity {
        self.performFetchIfNeeded()
        return self.rawValue.object(at: indexPath)
    }
    
    public func indexPath(for object: Entity) -> IndexPath? {
        self.performFetchIfNeeded()
        return self.rawValue.indexPath(forObject: object)
    }
    
}

extension FetchRequestController {
    
    public func numberOfSections() -> Int {
        self.performFetchIfNeeded()
        return self.sections.count
    }
    
    public func numberOfObjects(inSection section: Int) -> Int {
        self.performFetchIfNeeded()
        return self.sections[section].numberOfObjects
    }
    
}

extension FetchRequestController {
    
    public var sections: [FetchedResultsSectionInfo<Entity>] {
        self.performFetchIfNeeded()

        guard let result = self.rawValue.sections?.map({ FetchedResultsSectionInfo<Entity>(rawValue: $0) }) else {
            fatalError("performFetch: hasn't been called.")
        }
        
        return result
    }
    
    public func section(forSectionIndexTitle title: String, at sectionIndex: Int) -> Int {
        self.performFetchIfNeeded()

        return self.rawValue.section(forSectionIndexTitle: title, at: sectionIndex)
    }
    
}

extension FetchRequestController {
    
    public func sectionIndexTitle(forSectionName sectionName: String) -> String? {
        self.performFetchIfNeeded()
        return self.rawValue.sectionIndexTitle(forSectionName: sectionName)
    }
    
    public var sectionIndexTitles: [String] {
        self.performFetchIfNeeded()
        return self.rawValue.sectionIndexTitles
    }
    
}

// MARK: -

extension FetchRequestController {
    
    public func refresh(using predicate: Predicate<Entity>?, keepOriginalPredicate: Bool) {
        self.assignPredicate(predicate, keepOriginalPredicate: keepOriginalPredicate)
        self.refresh()
    }

    public func refresh(using rawValue: NSPredicate, keepOriginalPredicate: Bool) {
        self.assignPredicate(Predicate<Entity>(rawValue: rawValue), keepOriginalPredicate: keepOriginalPredicate)
        self.refresh()
    }

    public func refresh(using sortDescriptors: [SortDescriptor<Entity>]?, keepOriginalSortDescriptors: Bool) {
        self.assignSortDescriptors(sortDescriptors, keepOriginalSortDescriptors: keepOriginalSortDescriptors)
        self.refresh()
    }

    public func refresh(using rawValues: [NSSortDescriptor], keepOriginalSortDescriptors: Bool) {
        self.assignSortDescriptors(rawValues.map({ SortDescriptor<Entity>(rawValue: $0) }), keepOriginalSortDescriptors: keepOriginalSortDescriptors)
        self.refresh()
    }

    public func refresh(using predicate: Predicate<Entity>?, sortDescriptors: [SortDescriptor<Entity>]?, keepOriginalPredicate: Bool, keepOriginalSortDescriptors: Bool) {
        self.assignPredicate(predicate, keepOriginalPredicate: keepOriginalPredicate)
        self.assignSortDescriptors(sortDescriptors, keepOriginalSortDescriptors: keepOriginalSortDescriptors)
        
        self.refresh()
    }

    public func refresh(using predicateRawValue: NSPredicate, sortDescriptors sortDescriptorRawValues: [NSSortDescriptor], keepOriginalPredicate: Bool, keepOriginalSortDescriptors: Bool) {
        self.assignPredicate(Predicate<Entity>(rawValue: predicateRawValue), keepOriginalPredicate: keepOriginalPredicate)
        self.assignSortDescriptors(sortDescriptorRawValues.map({ SortDescriptor<Entity>(rawValue: $0) }), keepOriginalSortDescriptors: keepOriginalSortDescriptors)
        
        self.refresh()
    }

    //
    
    public func resetPredicate() {
        self.refresh(using: self.initialPredicate, keepOriginalPredicate: false)
    }
    
    public func resetSortDescriptors() {
        self.refresh(using: self.initialSortDescriptors, keepOriginalSortDescriptors: false)
    }
    
    public func resetPredicateAndSortDescriptors() {
        self.refresh(using: self.initialPredicate, sortDescriptors: self.initialSortDescriptors, keepOriginalPredicate: false, keepOriginalSortDescriptors: false)
    }
    
}

extension FetchRequestController {

    public func filter(using predicate: Predicate<Entity>) {
        self.refresh(using: predicate, keepOriginalPredicate: true)
    }

    public func filter(using predicateClosure: () -> Predicate<Entity>) {
        self.refresh(using: predicateClosure(), keepOriginalPredicate: true)
    }
    
    public func filter(using rawValue: NSPredicate) {
        self.refresh(using: Predicate<Entity>(rawValue: rawValue), keepOriginalPredicate: true)
    }

    
    public func resetFilter() {
        self.resetPredicate()
    }
    
    public func reset() {
        self.resetPredicateAndSortDescriptors()
    }
    
}

extension FetchRequestController {
    
    fileprivate func assignPredicate(_ predicate: Predicate<Entity>?, keepOriginalPredicate: Bool) {
        let newPredicate: Predicate<Entity>?
        
        if keepOriginalPredicate {
            if let initialPredicate = self.initialPredicate {
                if let predicate = predicate {
                    newPredicate = CompoundPredicate<Entity>(type: .and, subpredicates: [initialPredicate, predicate])
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
        
        self.rawValue.fetchRequest.predicate = newPredicate?.rawValue
    }
    
    fileprivate func assignSortDescriptors(_ sortDescriptors: [SortDescriptor<Entity>]?, keepOriginalSortDescriptors: Bool) {
        let newSortDescriptors: [SortDescriptor<Entity>]?
        
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
        
        self.rawValue.fetchRequest.sortDescriptors = newSortDescriptors?.map { $0.rawValue }
    }
    
}

