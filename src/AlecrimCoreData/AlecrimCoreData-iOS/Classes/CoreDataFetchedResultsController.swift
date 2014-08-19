//
//  CoreDataFetchedResultsController.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-08-09.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public final class CoreDataFetchedResultsController<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    
    // MARK: -
    
    private let fetchRequest: NSFetchRequest
    private let managedObjectContext: NSManagedObjectContext
    private let sectionNameKeyPath: String?
    private let cacheName: String? = nil

    private var hasUnderlyingFetchedResultsController = false
    
    private lazy var underlyingFetchedResultsController: NSFetchedResultsController = {
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: self.fetchRequest,
            managedObjectContext: self.managedObjectContext,
            sectionNameKeyPath: self.sectionNameKeyPath,
            cacheName: self.cacheName
        )
        
        fetchedResultsController.delegate = self
        
        var error: NSError? = nil
        let success = fetchedResultsController.performFetch(&error)

        self.hasUnderlyingFetchedResultsController = true

        return fetchedResultsController
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
        }
    }

    // MARK: - delegate support

    private var willChangeContentClosure: (() -> Void)?
    private var didChangeContentClosure: (() -> Void)?

    private var didInsertSectionClosure: ((CoreDataFetchedResultsSectionInfo<T>, Int) -> Void)?
    private var didDeleteSectionClosure: ((CoreDataFetchedResultsSectionInfo<T>, Int) -> Void)?

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
    
    public func didInsertSection(closure: (CoreDataFetchedResultsSectionInfo<T>, Int) -> Void) -> Self {
        self.didInsertSectionClosure = closure
        return self
    }

    public func didDeleteSection(closure: (CoreDataFetchedResultsSectionInfo<T>, Int) -> Void) -> Self {
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

    // MARK: - NSFetchedResultsControllerDelegate
    // TODO: move to an extension when Swift fixes the bug (Swift beta 5 and beta 6)

    public func controller(controller: NSFetchedResultsController!, didChangeObject anObject: AnyObject!, atIndexPath indexPath: NSIndexPath!, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath!) {
        switch type {
        case .Insert:
            self.didInsertEntityClosure?(anObject as T, newIndexPath)
            
        case .Delete:
            self.didDeleteEntityClosure?(anObject as T, indexPath)

        case .Update:
            self.didUpdateEntityClosure?(anObject as T, indexPath)
            
        case .Move:
            self.didMoveEntityClosure?(anObject as T, indexPath, newIndexPath)

        default:
            break
        }
    }
    
    public func controller(controller: NSFetchedResultsController!, didChangeSection sectionInfo: NSFetchedResultsSectionInfo!, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.didInsertSectionClosure?(CoreDataFetchedResultsSectionInfo(underlyingSectionInfo: sectionInfo), sectionIndex)
            
        case .Delete:
            self.didDeleteSectionClosure?(CoreDataFetchedResultsSectionInfo(underlyingSectionInfo: sectionInfo), sectionIndex)
            
        default:
            break
        }
    }
    
    public func controllerWillChangeContent(controller: NSFetchedResultsController!) {
        self.willChangeContentClosure?()
    }
    
    public func controllerDidChangeContent(controller: NSFetchedResultsController!) {
        self.didChangeContentClosure?()
    }
    
    public func controller(controller: NSFetchedResultsController!, sectionIndexTitleForSectionName sectionName: String!) -> String! {
        return self.sectionIndexTitleClosure?(sectionName)
    }
}

extension CoreDataFetchedResultsController {
    
    public class func deleteCacheWithName(name: String) {
        NSFetchedResultsController.deleteCacheWithName(name)
    }
    
}

extension CoreDataFetchedResultsController {
 
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

extension CoreDataFetchedResultsController {
    
    public var sections: [CoreDataFetchedResultsSectionInfo<T>]! {
        if let underlyingSections = self.underlyingFetchedResultsController.sections as? [NSFetchedResultsSectionInfo] {
            return underlyingSections.map { CoreDataFetchedResultsSectionInfo<T>(underlyingSectionInfo: $0) }
        }
        else {
            return nil
        }
    }
    
    public func sectionForSectionIndexTitle(title: String, atIndex sectionIndex: Int) -> Int {
        return self.underlyingFetchedResultsController.sectionForSectionIndexTitle(title, atIndex: sectionIndex)
    }
    
}

extension CoreDataFetchedResultsController {
    
    public var sectionIndexTitles: [String]! {
        return self.underlyingFetchedResultsController.sectionIndexTitles as? [String]
    }
    
    public func sectionIndexTitleForSectionName(sectionName: String) -> String! {
        return self.underlyingFetchedResultsController.sectionIndexTitleForSectionName(sectionName)
    }

}

