//
//  FetchRequestControllerDelegate.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-26.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

internal final class FetchRequestControllerDelegate<T: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    
    private var needsReloadDataClosure: (() -> Void)?
    
    private lazy var willChangeContentClosures = Array<() -> Void>()
    private lazy var didChangeContentClosures = Array<() -> Void>()
    
    private lazy var didInsertSectionClosures = Array<(FetchRequestControllerSection<T>, Int) -> Void>()
    private lazy var didDeleteSectionClosures = Array<(FetchRequestControllerSection<T>, Int) -> Void>()
    private lazy var didUpdateSectionClosures = Array<(FetchRequestControllerSection<T>, Int) -> Void>()
    
    private lazy var didInsertEntityClosures = Array<(T, NSIndexPath) -> Void>()
    private lazy var didDeleteEntityClosures = Array<(T, NSIndexPath) -> Void>()
    private lazy var didUpdateEntityClosures = Array<(T, NSIndexPath) -> Void>()
    private lazy var didMoveEntityClosures = Array<(T, NSIndexPath, NSIndexPath) -> Void>()
    
    private var sectionIndexTitleClosure: ((String) -> String?)?

    // MARK: - NSFetchedResultsControllerDelegate methods
    
    @objc func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            for closure in self.didInsertEntityClosures {
                closure(anObject as! T, newIndexPath!)
            }
            
        case .Delete:
            for closure in self.didDeleteEntityClosures {
                closure(anObject as! T, indexPath!)
            }
            
        case .Update:
            for closure in self.didUpdateEntityClosures {
                closure(anObject as! T, indexPath!)
            }
            
        case .Move:
            for closure in self.didMoveEntityClosures {
                closure(anObject as! T, indexPath!, newIndexPath!)
            }
        }
    }
    
    @objc func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            for closure in self.didInsertSectionClosures {
                closure(FetchRequestControllerSection(underlyingSectionInfo: sectionInfo), sectionIndex)
            }
            
        case .Delete:
            for closure in self.didDeleteSectionClosures {
                closure(FetchRequestControllerSection(underlyingSectionInfo: sectionInfo), sectionIndex)
            }
            
        case .Update:
            for closure in self.didUpdateSectionClosures {
                closure(FetchRequestControllerSection(underlyingSectionInfo: sectionInfo), sectionIndex)
            }
            
        default:
            break
        }
    }
    
    @objc func controllerWillChangeContent(controller: NSFetchedResultsController) {
        for closure in self.willChangeContentClosures {
            closure()
        }
    }
    
    @objc func controllerDidChangeContent(controller: NSFetchedResultsController) {
        for closure in self.didChangeContentClosures {
            closure()
        }
    }
    
    @objc func controller(controller: NSFetchedResultsController, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return self.sectionIndexTitleClosure?(sectionName)
    }
}

// MARK: - FetchRequestController extensions

extension FetchRequestController {
    
    public func refresh() throws {
        self.delegate.needsReloadDataClosure?()
        
        for closure in self.delegate.willChangeContentClosures {
            closure()
        }
        
        if let cacheName = self.cacheName {
            FetchRequestController.deleteCacheWithName(cacheName)
        }
        
        try self.performFetch()
        
        for closure in self.delegate.didChangeContentClosures {
            closure()
        }
    }
    
}

extension FetchRequestController {
 
    internal func needsReloadData(closure: () -> Void) -> Self {
        self.delegate.needsReloadDataClosure = closure
        return self
    }

}

extension FetchRequestController {
    
    public func willChangeContent(closure: () -> Void) -> Self {
        self.delegate.willChangeContentClosures.append(closure)
        return self
    }
    
    public func didChangeContent(closure: () -> Void) -> Self {
        self.delegate.didChangeContentClosures.append(closure)
        return self
    }
    
    public func didInsertSection(closure: (FetchRequestControllerSection<T>, Int) -> Void) -> Self {
        self.delegate.didInsertSectionClosures.append(closure)
        return self
    }
    
    public func didDeleteSection(closure: (FetchRequestControllerSection<T>, Int) -> Void) -> Self {
        self.delegate.didDeleteSectionClosures.append(closure)
        return self
    }
    
    public func didUpdateSection(closure: (FetchRequestControllerSection<T>, Int) -> Void) -> Self {
        self.delegate.didUpdateSectionClosures.append(closure)
        return self
    }
    
    public func didInsertEntity(closure: (T, NSIndexPath) -> Void) -> Self {
        self.delegate.didInsertEntityClosures.append(closure)
        return self
    }
    
    public func didDeleteEntity(closure: (T, NSIndexPath) -> Void) -> Self {
        self.delegate.didDeleteEntityClosures.append(closure)
        return self
    }
    
    public func didUpdateEntity(closure: (T, NSIndexPath) -> Void) -> Self {
        self.delegate.didUpdateEntityClosures.append(closure)
        return self
    }
    
    public func didMoveEntity(closure: (T, NSIndexPath, NSIndexPath) -> Void) -> Self {
        self.delegate.didMoveEntityClosures.append(closure)
        return self
    }
    
    public func sectionIndexTitle(closure: (String) -> String?) -> Self {
        self.delegate.sectionIndexTitleClosure = closure
        return self
    }
    
}
