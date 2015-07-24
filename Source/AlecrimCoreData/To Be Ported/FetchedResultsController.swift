//
//  FetchedResultsController.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-08-09.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public final class FetchedResultsController<T: NSManagedObject> {
    
    // MARK: -
    
    private var initialFetchRequest: NSFetchRequest!
    private let initialManagedObjectContext: NSManagedObjectContext
    private let initialSectionNameKeyPath: String?
    private let initialCacheName: String?
    
    private let initialPredicate: NSPredicate?
    private let initialSortDescriptors: [NSSortDescriptor]?
    
    private var hasUnderlyingFetchedResultsController = false
    private var underlyingFecthedResultsControllerDelegate: FecthedResultsControllerDelegate! = nil
    
    private lazy var underlyingFetchedResultsController: NSFetchedResultsController = {
        let frc = NSFetchedResultsController(fetchRequest: self.initialFetchRequest, managedObjectContext: self.initialManagedObjectContext, sectionNameKeyPath: self.initialSectionNameKeyPath, cacheName: self.initialCacheName)
        
        // we have to retain the delegate first
        self.underlyingFecthedResultsControllerDelegate = FecthedResultsControllerDelegate(fetchedResultsController: unsafeBitCast(self, FetchedResultsController<NSManagedObject>.self))
        frc.delegate = self.underlyingFecthedResultsControllerDelegate
        
        var error: NSError? = nil
        let success = frc.performFetch(&error)
        
        self.hasUnderlyingFetchedResultsController = true
        
        return frc
        }()
    
    internal init(fetchRequest: NSFetchRequest, managedObjectContext: NSManagedObjectContext, sectionNameKeyPath: String? = nil, cacheName: String? = nil) {
        self.initialFetchRequest = fetchRequest
        self.initialManagedObjectContext = managedObjectContext
        self.initialSectionNameKeyPath = sectionNameKeyPath
        self.initialCacheName = cacheName
        
        self.initialPredicate = fetchRequest.predicate?.copy() as? NSPredicate
        self.initialSortDescriptors = fetchRequest.sortDescriptors as? [NSSortDescriptor]
    }
    
    deinit {
        if self.hasUnderlyingFetchedResultsController {
            self.underlyingFetchedResultsController.delegate = nil
            self.underlyingFecthedResultsControllerDelegate = nil
        }
    }
    
    // MARK: - delegate support

    private var needsReloadDataClosure: (() -> Void)?
    
    private lazy var willChangeContentClosures = Array<() -> Void>()
    private lazy var didChangeContentClosures = Array<() -> Void>()
    
    private lazy var didInsertSectionClosures = Array<(FetchedResultsSectionInfo<T>, Int) -> Void>()
    private lazy var didDeleteSectionClosures = Array<(FetchedResultsSectionInfo<T>, Int) -> Void>()
    private lazy var didUpdateSectionClosures = Array<(FetchedResultsSectionInfo<T>, Int) -> Void>()
    
    private lazy var didInsertEntityClosures = Array<(T, NSIndexPath) -> Void>()
    private lazy var didDeleteEntityClosures = Array<(T, NSIndexPath) -> Void>()
    private lazy var didUpdateEntityClosures = Array<(T, NSIndexPath) -> Void>()
    private lazy var didMoveEntityClosures = Array<(T, NSIndexPath, NSIndexPath) -> Void>()
    
    private var sectionIndexTitleClosure: ((String) -> String!)?

    private func needsReloadData(closure: () -> Void) -> Self {
        self.needsReloadDataClosure = closure
        return self
    }

    public func willChangeContent(closure: () -> Void) -> Self {
        self.willChangeContentClosures.append(closure)
        return self
    }
    
    public func didChangeContent(closure: () -> Void) -> Self {
        self.didChangeContentClosures.append(closure)
        return self
    }
    
    public func didInsertSection(closure: (FetchedResultsSectionInfo<T>, Int) -> Void) -> Self {
        self.didInsertSectionClosures.append(closure)
        return self
    }
    
    public func didDeleteSection(closure: (FetchedResultsSectionInfo<T>, Int) -> Void) -> Self {
        self.didDeleteSectionClosures.append(closure)
        return self
    }

    public func didUpdateSection(closure: (FetchedResultsSectionInfo<T>, Int) -> Void) -> Self {
        self.didUpdateSectionClosures.append(closure)
        return self
    }

    public func didInsertEntity(closure: (T, NSIndexPath) -> Void) -> Self {
        self.didInsertEntityClosures.append(closure)
        return self
    }
    
    public func didDeleteEntity(closure: (T, NSIndexPath) -> Void) -> Self {
        self.didDeleteEntityClosures.append(closure)
        return self
    }
    
    public func didUpdateEntity(closure: (T, NSIndexPath) -> Void) -> Self {
        self.didUpdateEntityClosures.append(closure)
        return self
    }
    
    public func didMoveEntity(closure: (T, NSIndexPath, NSIndexPath) -> Void) -> Self {
        self.didMoveEntityClosures.append(closure)
        return self
    }
    
    public func sectionIndexTitle(closure: (String) -> String!) -> Self {
        self.sectionIndexTitleClosure = closure
        return self
    }
    
}

extension FetchedResultsController {
    
    public class func deleteCacheWithName(name: String) {
        NSFetchedResultsController.deleteCacheWithName(name)
    }
    
}
    
extension FetchedResultsController {
    
    public var fetchRequest: NSFetchRequest {
        return self.underlyingFetchedResultsController.fetchRequest
    }
    
    public func performFetch(error: NSErrorPointer) -> Bool {
        if let cacheName = self.underlyingFetchedResultsController.cacheName {
            FetchedResultsController.deleteCacheWithName(cacheName)
        }
        
        return self.underlyingFetchedResultsController.performFetch(error)
    }
    
    public func refresh() -> (success: Bool, error: NSError?) {
        self.needsReloadDataClosure?()
        
        for closure in self.willChangeContentClosures {
            closure()
        }
        
        var error: NSError? = nil
        let success = self.performFetch(&error)

        for closure in self.didChangeContentClosures {
            closure()
        }
        
        return (success, error)
    }
    
}
    
extension FetchedResultsController {
    
    public func refreshWithPredicate(predicate: NSPredicate?, keepOriginalPredicate: Bool = false) -> (success: Bool, error: NSError?) {
        self.assignPredicate(predicate, keepOriginalPredicate: keepOriginalPredicate)
        
        return self.refresh()
    }

    public func refreshWithSortDescriptors(sortDescriptors: [NSSortDescriptor]?, keepOriginalSortDescriptors: Bool = false) -> (success: Bool, error: NSError?) {
        self.assignSortDescriptors(sortDescriptors, keepOriginalSortDescriptors: keepOriginalSortDescriptors)
        
        return self.refresh()
    }

    public func refreshWithPredicate(predicate: NSPredicate?, andSortDescriptors sortDescriptors: [NSSortDescriptor]?, keepOriginalPredicate: Bool = true, keepOriginalSortDescriptors: Bool = true) -> (success: Bool, error: NSError?) {
        self.assignPredicate(predicate, keepOriginalPredicate: keepOriginalPredicate)
        self.assignSortDescriptors(sortDescriptors, keepOriginalSortDescriptors: keepOriginalSortDescriptors)
        
        return self.refresh()
    }
    
    public func resetPredicate() -> (success: Bool, error: NSError?) {
        return self.refreshWithPredicate(self.initialPredicate, keepOriginalPredicate: false)
    }
    
    public func resetSortDescriptors() -> (success: Bool, error: NSError?) {
        return self.refreshWithSortDescriptors(self.initialSortDescriptors, keepOriginalSortDescriptors: false)
    }
    
    public func resetPredicateAndSortDescriptors() -> (success: Bool, error: NSError?) {
        return self.refreshWithPredicate(self.initialPredicate, andSortDescriptors: self.initialSortDescriptors, keepOriginalPredicate: false, keepOriginalSortDescriptors: false)
    }
    
}
    
extension FetchedResultsController {
    
    public func filter(predicateClosure: (T.Type) -> NSPredicate) -> (success: Bool, error: NSError?) {
        let predicate = predicateClosure(T.self)
        return self.refreshWithPredicate(predicate, keepOriginalPredicate: true)
    }

    public func resetFilter() -> (success: Bool, error: NSError?) {
        return self.resetPredicate()
    }
    
    public func reset() -> (success: Bool, error: NSError?) {
        return self.resetPredicateAndSortDescriptors()
    }
        
}
    
extension FetchedResultsController {
    
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

extension FetchedResultsController {
    
    public var entities: [T]! {
        return self.underlyingFetchedResultsController.fetchedObjects as? [T]
    }
    
    public func entityAtIndexPath(indexPath: NSIndexPath) -> T {
        return self.underlyingFetchedResultsController.objectAtIndexPath(indexPath) as! T
    }
    
    public func indexPathForEntity(entity: T) -> NSIndexPath? {
        return self.underlyingFetchedResultsController.indexPathForObject(entity)
    }
    
}

extension FetchedResultsController {
    
    public var sections: [FetchedResultsSectionInfo<T>] {
        if let underlyingSections = self.underlyingFetchedResultsController.sections as? [NSFetchedResultsSectionInfo] {
            return underlyingSections.map { FetchedResultsSectionInfo<T>(underlyingSectionInfo: $0) }
        }
        else {
            return [FetchedResultsSectionInfo<T>]() // always return a valid array
        }
    }
    
    public func sectionForSectionIndexTitle(title: String, atIndex sectionIndex: Int) -> Int {
        return self.underlyingFetchedResultsController.sectionForSectionIndexTitle(title, atIndex: sectionIndex)
    }
    
}

extension FetchedResultsController {
    
    public var sectionIndexTitles: [String] {
        return self.underlyingFetchedResultsController.sectionIndexTitles as! [String]
    }
    
    public func sectionIndexTitleForSectionName(sectionName: String) -> String? {
        return self.underlyingFetchedResultsController.sectionIndexTitleForSectionName(sectionName)
    }
    
}

// MARK: - delegate class

@objc(ALCFecthedResultsControllerDelegate)
private class FecthedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {
    
    unowned let fetchedResultsController: FetchedResultsController<NSManagedObject>
    
    init(fetchedResultsController: FetchedResultsController<NSManagedObject>) {
        self.fetchedResultsController = fetchedResultsController
        super.init()
    }
    
    @objc func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            for closure in self.fetchedResultsController.didInsertEntityClosures {
                closure(anObject as! NSManagedObject, newIndexPath!)
            }
            
        case .Delete:
            for closure in self.fetchedResultsController.didDeleteEntityClosures {
                closure(anObject as! NSManagedObject, indexPath!)
            }
            
        case .Update:
            for closure in self.fetchedResultsController.didUpdateEntityClosures {
                closure(anObject as! NSManagedObject, indexPath!)
            }
            
        case .Move:
            for closure in self.fetchedResultsController.didMoveEntityClosures {
                closure(anObject as! NSManagedObject, indexPath!, newIndexPath!)
            }
            
        default:
            break
        }
    }
    
    @objc func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            for closure in self.fetchedResultsController.didInsertSectionClosures {
                closure(FetchedResultsSectionInfo(underlyingSectionInfo: sectionInfo), sectionIndex)
            }
            
        case .Delete:
            for closure in self.fetchedResultsController.didDeleteSectionClosures {
                closure(FetchedResultsSectionInfo(underlyingSectionInfo: sectionInfo), sectionIndex)
            }
            
        case .Update:
            for closure in self.fetchedResultsController.didUpdateSectionClosures {
                closure(FetchedResultsSectionInfo(underlyingSectionInfo: sectionInfo), sectionIndex)
            }
            
        default:
            break
        }
    }
    
    @objc func controllerWillChangeContent(controller: NSFetchedResultsController) {
        for closure in self.fetchedResultsController.willChangeContentClosures {
            closure()
        }
    }
    
    @objc func controllerDidChangeContent(controller: NSFetchedResultsController) {
        for closure in self.fetchedResultsController.didChangeContentClosures {
            closure()
        }
    }
    
    @objc func controller(controller: NSFetchedResultsController, sectionIndexTitleForSectionName sectionName: String?) -> String? {
        return self.fetchedResultsController.sectionIndexTitleClosure?(sectionName!)
    }

}

// MARK: - Helper Extensions - iOS

#if os(iOS)
    
extension FetchedResultsController {
    
    public func bindToTableView(tableView: UITableView, rowAnimation: UITableViewRowAnimation = .Fade, reloadRowAtIndexPath reloadRowAtIndexPathClosure: (NSIndexPath -> Void)? = nil) -> Self {
        var insertedSectionIndexes = NSMutableIndexSet()
        var deletedSectionIndexes = NSMutableIndexSet()
        var updatedSectionIndexes = NSMutableIndexSet()
        
        var insertedItemIndexPaths = [NSIndexPath]()
        var deletedItemIndexPaths = [NSIndexPath]()
        var updatedItemIndexPaths = [NSIndexPath]()
        
        var reloadData = false
        
        self
            .needsReloadData {
                reloadData = true
            }
            .willChangeContent {
                if !reloadData {
                    insertedSectionIndexes.removeAllIndexes()
                    deletedSectionIndexes.removeAllIndexes()
                    updatedSectionIndexes.removeAllIndexes()
                    
                    insertedItemIndexPaths.removeAll(keepCapacity: false)
                    deletedItemIndexPaths.removeAll(keepCapacity: false)
                    updatedItemIndexPaths.removeAll(keepCapacity: false)

                    //
                    tableView.beginUpdates()
                }
            }
            .didInsertSection { sectionInfo, sectionIndex in
                if !reloadData {
                    insertedSectionIndexes.addIndex(sectionIndex)
                }
            }
            .didDeleteSection { sectionInfo, sectionIndex in
                if !reloadData {
                    deletedSectionIndexes.addIndex(sectionIndex)
                    deletedItemIndexPaths = deletedItemIndexPaths.filter { $0.section != sectionIndex }
                    updatedItemIndexPaths = updatedItemIndexPaths.filter { $0.section != sectionIndex }
                }
            }
            .didUpdateSection { sectionInfo, sectionIndex in
                if !reloadData {
                    updatedSectionIndexes.addIndex(sectionIndex)
                }
            }
            .didInsertEntity { entity, newIndexPath in
                if !reloadData {
                    if !insertedSectionIndexes.containsIndex(newIndexPath.section) {
                        insertedItemIndexPaths.append(newIndexPath)
                    }
                }
            }
            .didDeleteEntity { entity, indexPath in
                if !reloadData {
                    if !deletedSectionIndexes.containsIndex(indexPath.section) {
                        deletedItemIndexPaths.append(indexPath)
                    }
                }
            }
            .didUpdateEntity { entity, indexPath in
                if !reloadData {
                    if !deletedSectionIndexes.containsIndex(indexPath.section) && find(deletedItemIndexPaths, indexPath) == nil && find(updatedItemIndexPaths, indexPath) == nil {
                        updatedItemIndexPaths.append(indexPath)
                    }
                }
            }
            .didMoveEntity { entity, indexPath, newIndexPath in
                if !reloadData {
                    if !deletedSectionIndexes.containsIndex(indexPath.section) {
                        deletedItemIndexPaths.append(indexPath)
                    }
                    
                    if !insertedSectionIndexes.containsIndex(newIndexPath.section) {
                        insertedItemIndexPaths.append(newIndexPath)
                    }
                }
            }
            .didChangeContent { [unowned tableView] in
                if reloadData {
                    tableView.reloadData()
                }
                else {
                    if deletedSectionIndexes.count > 0 {
                        tableView.deleteSections(deletedSectionIndexes, withRowAnimation: rowAnimation)
                    }
                    
                    if insertedSectionIndexes.count > 0 {
                        tableView.insertSections(insertedSectionIndexes, withRowAnimation: rowAnimation)
                    }
                    
                    if updatedSectionIndexes.count > 0 {
                        tableView.reloadSections(updatedSectionIndexes, withRowAnimation: rowAnimation)
                    }
                    
                    if deletedItemIndexPaths.count > 0 {
                        tableView.deleteRowsAtIndexPaths(deletedItemIndexPaths, withRowAnimation: rowAnimation)
                    }
                    
                    if insertedItemIndexPaths.count > 0 {
                        tableView.insertRowsAtIndexPaths(insertedItemIndexPaths, withRowAnimation: rowAnimation)
                    }
                    
                    if updatedItemIndexPaths.count > 0 && reloadRowAtIndexPathClosure == nil {
                        tableView.reloadRowsAtIndexPaths(updatedItemIndexPaths, withRowAnimation: rowAnimation)
                    }
                    
                    tableView.endUpdates()
                    
                    if let reloadRowAtIndexPathClosure = reloadRowAtIndexPathClosure {
                        for updatedItemIndexPath in updatedItemIndexPaths {
                            reloadRowAtIndexPathClosure(updatedItemIndexPath)
                        }
                    }
                }

                //
                insertedSectionIndexes.removeAllIndexes()
                deletedSectionIndexes.removeAllIndexes()
                updatedSectionIndexes.removeAllIndexes()
                
                insertedItemIndexPaths.removeAll(keepCapacity: false)
                deletedItemIndexPaths.removeAll(keepCapacity: false)
                updatedItemIndexPaths.removeAll(keepCapacity: false)
                
                reloadData = false
            }
        
        return self
    }

    public func bindToCollectionView(collectionView: UICollectionView, reloadItemAtIndexPath reloadItemAtIndexPathClosure: (NSIndexPath -> Void)? = nil) -> Self {
        var insertedSectionIndexes = NSMutableIndexSet()
        var deletedSectionIndexes = NSMutableIndexSet()
        var updatedSectionIndexes = NSMutableIndexSet()
        
        var insertedItemIndexPaths = [NSIndexPath]()
        var deletedItemIndexPaths = [NSIndexPath]()
        var updatedItemIndexPaths = [NSIndexPath]()
        
        var reloadData = false
        
        self
            .needsReloadData {
                reloadData = true
            }
            .willChangeContent {
                if !reloadData {
                    insertedSectionIndexes.removeAllIndexes()
                    deletedSectionIndexes.removeAllIndexes()
                    updatedSectionIndexes.removeAllIndexes()
                    
                    insertedItemIndexPaths.removeAll(keepCapacity: false)
                    deletedItemIndexPaths.removeAll(keepCapacity: false)
                    updatedItemIndexPaths.removeAll(keepCapacity: false)
                }
            }
            .didInsertSection { sectionInfo, sectionIndex in
                if !reloadData {
                    insertedSectionIndexes.addIndex(sectionIndex)
                }
            }
            .didDeleteSection { sectionInfo, sectionIndex in
                // TODO: find out more info about the UICollectionView issue about section deletions
                reloadData = true

//                if !reloadData {
//                    deletedSectionIndexes.addIndex(sectionIndex)
//                    deletedItemIndexPaths = deletedItemIndexPaths.filter { $0.section != sectionIndex }
//                    updatedItemIndexPaths = updatedItemIndexPaths.filter { $0.section != sectionIndex }
//                }
            }
            .didUpdateSection { sectionInfo, sectionIndex in
                if !reloadData {
                    updatedSectionIndexes.addIndex(sectionIndex)
                }
            }
            .didInsertEntity { entity, newIndexPath in
                if !reloadData {
                    if !insertedSectionIndexes.containsIndex(newIndexPath.section) {
                        insertedItemIndexPaths.append(newIndexPath)
                    }
                }
            }
            .didDeleteEntity { entity, indexPath in
                if !reloadData {
                    if !deletedSectionIndexes.containsIndex(indexPath.section) {
                        deletedItemIndexPaths.append(indexPath)
                    }
                }
            }
            .didUpdateEntity { entity, indexPath in
                if !reloadData {
                    if !deletedSectionIndexes.containsIndex(indexPath.section) && find(deletedItemIndexPaths, indexPath) == nil && find(updatedItemIndexPaths, indexPath) == nil {
                        updatedItemIndexPaths.append(indexPath)
                    }
                }
            }
            .didMoveEntity { entity, indexPath, newIndexPath in
                if !reloadData {
                    if !deletedSectionIndexes.containsIndex(indexPath.section) {
                        deletedItemIndexPaths.append(indexPath)
                    }
                    
                    if !insertedSectionIndexes.containsIndex(newIndexPath.section) {
                        insertedItemIndexPaths.append(newIndexPath)
                    }
                }
            }
            .didChangeContent { [unowned collectionView] in
                if reloadData {
                    collectionView.reloadData()
                    
                    insertedSectionIndexes.removeAllIndexes()
                    deletedSectionIndexes.removeAllIndexes()
                    updatedSectionIndexes.removeAllIndexes()
                    
                    insertedItemIndexPaths.removeAll(keepCapacity: false)
                    deletedItemIndexPaths.removeAll(keepCapacity: false)
                    updatedItemIndexPaths.removeAll(keepCapacity: false)
                    
                    reloadData = false
                }
                else {
                    collectionView.performBatchUpdates({
                        if deletedSectionIndexes.count > 0 {
                            collectionView.deleteSections(deletedSectionIndexes)
                        }
                        
                        if insertedSectionIndexes.count > 0 {
                            collectionView.insertSections(insertedSectionIndexes)
                        }
                        
                        if updatedSectionIndexes.count > 0 {
                            collectionView.reloadSections(updatedSectionIndexes)
                        }
                        
                        if deletedItemIndexPaths.count > 0 {
                            collectionView.deleteItemsAtIndexPaths(deletedItemIndexPaths)
                        }
                        
                        if insertedItemIndexPaths.count > 0 {
                            collectionView.insertItemsAtIndexPaths(insertedItemIndexPaths)
                        }
                        
                        if updatedItemIndexPaths.count > 0 && reloadItemAtIndexPathClosure == nil {
                            collectionView.reloadItemsAtIndexPaths(updatedItemIndexPaths)
                        }
                        },
                        completion: { finished in
                            if finished {
                                if let reloadItemAtIndexPathClosure = reloadItemAtIndexPathClosure {
                                    for updatedItemIndexPath in updatedItemIndexPaths {
                                        reloadItemAtIndexPathClosure(updatedItemIndexPath)
                                    }
                                }
                                
                                insertedSectionIndexes.removeAllIndexes()
                                deletedSectionIndexes.removeAllIndexes()
                                updatedSectionIndexes.removeAllIndexes()
                                
                                insertedItemIndexPaths.removeAll(keepCapacity: false)
                                deletedItemIndexPaths.removeAll(keepCapacity: false)
                                updatedItemIndexPaths.removeAll(keepCapacity: false)
                                
                                reloadData = false
                            }
                    })
                }
            }
        
        return self
    }

}

#endif
