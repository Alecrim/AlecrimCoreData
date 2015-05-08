//
//  FetchedResultsController.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-08-09.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

#if os(iOS)
    
import Foundation
import CoreData

public final class FetchedResultsController<T: NSManagedObject> {
    
    // MARK: -
    
    private var initialFetchRequest: NSFetchRequest!
    private let initialManagedObjectContext: NSManagedObjectContext
    private let initialSectionNameKeyPath: String?
    private let initialCacheName: String?
    
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
    }
    
    deinit {
        if self.hasUnderlyingFetchedResultsController {
            self.underlyingFetchedResultsController.delegate = nil
            self.underlyingFecthedResultsControllerDelegate = nil
        }
    }
    
    // MARK: - delegate support
    
    private var willChangeContentClosure: (() -> Void)?
    private var didChangeContentClosure: (() -> Void)?
    
    private var didInsertSectionClosure: ((FetchedResultsSectionInfo<T>, Int) -> Void)?
    private var didDeleteSectionClosure: ((FetchedResultsSectionInfo<T>, Int) -> Void)?
    private var didUpdateSectionClosure: ((FetchedResultsSectionInfo<T>, Int) -> Void)?
    
    private var didInsertEntityClosure: ((T, NSIndexPath) -> Void)?
    private var didDeleteEntityClosure: ((T, NSIndexPath) -> Void)?
    private var didUpdateEntityClosure: ((T, NSIndexPath) -> Void)?
    private var didMoveEntityClosure: ((T, NSIndexPath, NSIndexPath) -> Void)?
    
    private var sectionIndexTitleClosure: ((String) -> String!)?
    
    public func willChangeContent(closure: () -> Void) -> Self {
        self.willChangeContentClosure = closure
        return self
    }
    
    public func didChangeContent(closure: () -> Void) -> Self {
        self.didChangeContentClosure = closure
        return self
    }
    
    public func didInsertSection(closure: (FetchedResultsSectionInfo<T>, Int) -> Void) -> Self {
        self.didInsertSectionClosure = closure
        return self
    }
    
    public func didDeleteSection(closure: (FetchedResultsSectionInfo<T>, Int) -> Void) -> Self {
        self.didDeleteSectionClosure = closure
        return self
    }

    public func didUpdateSection(closure: (FetchedResultsSectionInfo<T>, Int) -> Void) -> Self {
        self.didUpdateSectionClosure = closure
        return self
    }

    public func didInsertEntity(closure: (T, NSIndexPath) -> Void) -> Self {
        self.didInsertEntityClosure = closure
        return self
    }
    
    public func didDeleteEntity(closure: (T, NSIndexPath) -> Void) -> Self {
        self.didDeleteEntityClosure = closure
        return self
    }
    
    public func didUpdateEntity(closure: (T, NSIndexPath) -> Void) -> Self {
        self.didUpdateEntityClosure = closure
        return self
    }
    
    public func didMoveEntity(closure: (T, NSIndexPath, NSIndexPath) -> Void) -> Self {
        self.didMoveEntityClosure = closure
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
    
    public func refresh() -> (Bool, NSError?) {
        var error: NSError? = nil
        let success = self.performFetch(&error)
        
        return (success, error)
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
    
    public var sections: [FetchedResultsSectionInfo<T>]! {
        if let underlyingSections = self.underlyingFetchedResultsController.sections as? [NSFetchedResultsSectionInfo] {
            return underlyingSections.map { FetchedResultsSectionInfo<T>(underlyingSectionInfo: $0) }
        }
        else {
            return nil
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
            self.fetchedResultsController.didInsertEntityClosure?(anObject as! NSManagedObject, newIndexPath!)
            
        case .Delete:
            self.fetchedResultsController.didDeleteEntityClosure?(anObject as! NSManagedObject, indexPath!)
            
        case .Update:
            self.fetchedResultsController.didUpdateEntityClosure?(anObject as! NSManagedObject, indexPath!)
            
        case .Move:
            self.fetchedResultsController.didMoveEntityClosure?(anObject as! NSManagedObject, indexPath!, newIndexPath!)
            
        default:
            break
        }
    }
    
    @objc func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.fetchedResultsController.didInsertSectionClosure?(FetchedResultsSectionInfo(underlyingSectionInfo: sectionInfo), sectionIndex)
            
        case .Delete:
            self.fetchedResultsController.didDeleteSectionClosure?(FetchedResultsSectionInfo(underlyingSectionInfo: sectionInfo), sectionIndex)
            
        case .Update:
            self.fetchedResultsController.didUpdateSectionClosure?(FetchedResultsSectionInfo(underlyingSectionInfo: sectionInfo), sectionIndex)
            
        default:
            break
        }
    }
    
    @objc func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.fetchedResultsController.willChangeContentClosure?()
    }
    
    @objc func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.fetchedResultsController.didChangeContentClosure?()
    }
    
    @objc func controller(controller: NSFetchedResultsController, sectionIndexTitleForSectionName sectionName: String?) -> String? {
        return self.fetchedResultsController.sectionIndexTitleClosure?(sectionName!)
    }

}

// MARK: - Helper Extensions
    
extension FetchedResultsController {
    
    public func bindToTableView(tableView: UITableView, rowAnimation: UITableViewRowAnimation = .Fade) -> Self {
        self
            .willChangeContent { [unowned tableView] in
                tableView.beginUpdates()
            }
            .didInsertSection { [unowned tableView] sectionInfo, sectionIndex in
                tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: rowAnimation)
            }
            .didDeleteSection { [unowned tableView] sectionInfo, sectionIndex in
                tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: rowAnimation)
            }
            .didUpdateSection { [unowned tableView] sectionInfo, sectionIndex in
                tableView.reloadSections(NSIndexSet(index: sectionIndex), withRowAnimation: rowAnimation)
            }
            .didInsertEntity { [unowned tableView] entity, newIndexPath in
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: rowAnimation)
            }
            .didDeleteEntity { [unowned tableView] entity, indexPath in
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
            }
            .didUpdateEntity { [unowned tableView] entity, indexPath in
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
            }
            .didMoveEntity { [unowned tableView] entity, indexPath, newIndexPath in
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: rowAnimation)
            }
            .didChangeContent { [unowned tableView] in
                tableView.endUpdates()
            }
        
        return self
    }

    public func bindToCollectionView(collectionView: UICollectionView) -> Self {
        var insertedSectionIndexes = NSMutableIndexSet()
        var deletedSectionIndexes = NSMutableIndexSet()
        var updatedSectionIndexes = NSMutableIndexSet()
        
        var insertedItemIndexPaths = [NSIndexPath]()
        var deletedItemIndexPaths = [NSIndexPath]()
        var updatedItemIndexPaths = [NSIndexPath]()
        
        var hasMoves = false
        
        self
            .willChangeContent {
                insertedSectionIndexes.removeAllIndexes()
                deletedSectionIndexes.removeAllIndexes()
                updatedSectionIndexes.removeAllIndexes()
                
                insertedItemIndexPaths.removeAll(keepCapacity: false)
                deletedItemIndexPaths.removeAll(keepCapacity: false)
                updatedItemIndexPaths.removeAll(keepCapacity: false)
                
                hasMoves = false
            }
            .didInsertSection { sectionInfo, sectionIndex in
                insertedSectionIndexes.addIndex(sectionIndex)
            }
            .didDeleteSection { sectionInfo, sectionIndex in
                deletedSectionIndexes.addIndex(sectionIndex)
            }
            .didUpdateSection { sectionInfo, sectionIndex in
                updatedSectionIndexes.addIndex(sectionIndex)
            }
            .didInsertEntity { entity, newIndexPath in
                insertedItemIndexPaths.append(newIndexPath)
            }
            .didDeleteEntity { entity, indexPath in
                deletedItemIndexPaths.append(indexPath)
            }
            .didUpdateEntity { entity, indexPath in
                updatedItemIndexPaths.append(indexPath)
            }
            .didMoveEntity { entity, indexPath, newIndexPath in
                hasMoves = true
            }
            .didChangeContent { [unowned collectionView] in
                if hasMoves {
                    collectionView.reloadData()

                    insertedSectionIndexes.removeAllIndexes()
                    deletedSectionIndexes.removeAllIndexes()
                    updatedSectionIndexes.removeAllIndexes()
                    
                    insertedItemIndexPaths.removeAll(keepCapacity: false)
                    deletedItemIndexPaths.removeAll(keepCapacity: false)
                    updatedItemIndexPaths.removeAll(keepCapacity: false)
                    
                    hasMoves = false
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
                        
                        if updatedItemIndexPaths.count > 0 {
                            collectionView.reloadItemsAtIndexPaths(updatedItemIndexPaths)
                        }
                    },
                        completion: { finished in
                            if finished {
                                insertedSectionIndexes.removeAllIndexes()
                                deletedSectionIndexes.removeAllIndexes()
                                updatedSectionIndexes.removeAllIndexes()
                                
                                insertedItemIndexPaths.removeAll(keepCapacity: false)
                                deletedItemIndexPaths.removeAll(keepCapacity: false)
                                updatedItemIndexPaths.removeAll(keepCapacity: false)
                                
                                hasMoves = false
                            }
                    })
                }
            }
        
        return self
    }

}
    
#endif
