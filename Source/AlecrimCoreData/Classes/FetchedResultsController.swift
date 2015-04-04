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
    
    private let fetchRequest: NSFetchRequest
    private let managedObjectContext: NSManagedObjectContext
    private let sectionNameKeyPath: String?
    private let cacheName: String? = nil
    
    private var hasUnderlyingFetchedResultsController = false
    private var underlyingFecthedResultsControllerDelegate: FecthedResultsControllerDelegate! = nil
    
    private lazy var underlyingFetchedResultsController: NSFetchedResultsController = {
        let frc = NSFetchedResultsController(fetchRequest: self.fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: self.sectionNameKeyPath, cacheName: self.cacheName)
        
        // we have to retain the delegate first
        self.underlyingFecthedResultsControllerDelegate = FecthedResultsControllerDelegate(fetchedResultsController: unsafeBitCast(self, FetchedResultsController<NSManagedObject>.self))
        frc.delegate = self.underlyingFecthedResultsControllerDelegate
        
        var error: NSError? = nil
        let success = frc.performFetch(&error)
        
        self.hasUnderlyingFetchedResultsController = true
        
        return frc
        }()
    
    internal init(fetchRequest: NSFetchRequest, managedObjectContext: NSManagedObjectContext, sectionNameKeyPath: String? = nil, cacheName: String? = nil) {
        self.fetchRequest = fetchRequest
        self.managedObjectContext = managedObjectContext
        self.sectionNameKeyPath = sectionNameKeyPath
        self.cacheName = cacheName
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
    
    public var entities: [T] {
        return self.underlyingFetchedResultsController.fetchedObjects as [T]
    }
    
    public func entityAtIndexPath(indexPath: NSIndexPath) -> T! {
        return self.underlyingFetchedResultsController.objectAtIndexPath(indexPath) as? T
    }
    
    public func indexPathForEntity(entity: T) -> NSIndexPath! {
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
    
    public var sectionIndexTitles: [String]! {
        return self.underlyingFetchedResultsController.sectionIndexTitles as? [String]
    }
    
    public func sectionIndexTitleForSectionName(sectionName: String) -> String! {
        return self.underlyingFetchedResultsController.sectionIndexTitleForSectionName(sectionName)
    }
    
}

// MARK: - delegate class
// SWIFT_BUG: Error -> Swift does now understand a generic class as a delegate from NSFetchedResultsController. Workaround -> create a non-generic class.

@objc(ALCFecthedResultsControllerDelegate) private class FecthedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {
    
    unowned let fetchedResultsController: FetchedResultsController<NSManagedObject>
    
    init(fetchedResultsController: FetchedResultsController<NSManagedObject>) {
        self.fetchedResultsController = fetchedResultsController
        super.init()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            self.fetchedResultsController.didInsertEntityClosure?(anObject as NSManagedObject, newIndexPath!)
            
        case .Delete:
            self.fetchedResultsController.didDeleteEntityClosure?(anObject as NSManagedObject, indexPath!)
            
        case .Update:
            self.fetchedResultsController.didUpdateEntityClosure?(anObject as NSManagedObject, indexPath!)
            
        case .Move:
            self.fetchedResultsController.didMoveEntityClosure?(anObject as NSManagedObject, indexPath!, newIndexPath!)
            
        default:
            break
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.fetchedResultsController.didInsertSectionClosure?(FetchedResultsSectionInfo(underlyingSectionInfo: sectionInfo), sectionIndex)
            
        case .Delete:
            self.fetchedResultsController.didDeleteSectionClosure?(FetchedResultsSectionInfo(underlyingSectionInfo: sectionInfo), sectionIndex)
            
        default:
            break
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.fetchedResultsController.willChangeContentClosure?()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.fetchedResultsController.didChangeContentClosure?()
    }
    
    func controller(controller: NSFetchedResultsController, sectionIndexTitleForSectionName sectionName: String?) -> String? {
        return self.fetchedResultsController.sectionIndexTitleClosure?(sectionName!)
    }

}

// MARK: - Helper extensions

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
    
}

#endif
