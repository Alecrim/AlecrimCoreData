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
    
    fileprivate var needsReloadDataClosure: (() -> Void)?
    
    fileprivate lazy var willChangeContentClosures = Array<() -> Void>()
    fileprivate lazy var didChangeContentClosures = Array<() -> Void>()
    
    fileprivate lazy var didInsertSectionClosures = Array<(FetchRequestControllerSection<T>, Int) -> Void>()
    fileprivate lazy var didDeleteSectionClosures = Array<(FetchRequestControllerSection<T>, Int) -> Void>()
    fileprivate lazy var didUpdateSectionClosures = Array<(FetchRequestControllerSection<T>, Int) -> Void>()
    
    fileprivate lazy var didInsertObjectClosures = Array<(T, IndexPath) -> Void>()
    fileprivate lazy var didDeleteObjectClosures = Array<(T, IndexPath) -> Void>()
    fileprivate lazy var didUpdateObjectClosures = Array<(T, IndexPath) -> Void>()
    fileprivate lazy var didMoveObjectClosures = Array<(T, IndexPath, IndexPath) -> Void>()
    
    fileprivate var sectionIndexTitleClosure: ((String) -> String?)?

    // MARK: - NSFetchedResultsControllerDelegate methods
    
    @objc func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            for closure in self.didInsertObjectClosures {
                closure(anObject as! T, newIndexPath!)
            }
            
        case .delete:
            for closure in self.didDeleteObjectClosures {
                closure(anObject as! T, indexPath!)
            }
            
        case .update:
            for closure in self.didUpdateObjectClosures {
                closure(anObject as! T, indexPath!)
            }
            
        case .move:
            for closure in self.didMoveObjectClosures {
                closure(anObject as! T, indexPath!, newIndexPath!)
            }
        }
    }
    
    @objc func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            for closure in self.didInsertSectionClosures {
                closure(FetchRequestControllerSection(underlyingSectionInfo: sectionInfo), sectionIndex)
            }
            
        case .delete:
            for closure in self.didDeleteSectionClosures {
                closure(FetchRequestControllerSection(underlyingSectionInfo: sectionInfo), sectionIndex)
            }
            
        case .update:
            for closure in self.didUpdateSectionClosures {
                closure(FetchRequestControllerSection(underlyingSectionInfo: sectionInfo), sectionIndex)
            }
            
        default:
            break
        }
    }
    
    @objc func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        for closure in self.willChangeContentClosures {
            closure()
        }
    }
    
    @objc func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        for closure in self.didChangeContentClosures {
            closure()
        }
    }
    
    @objc func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return self.sectionIndexTitleClosure?(sectionName)
    }
}

// MARK: - FetchRequestController extensions

extension FetchRequestController {
    
    public func removeAllBindings() {
        self.delegate.needsReloadDataClosure = nil
        
        self.delegate.willChangeContentClosures.removeAll()
        self.delegate.didChangeContentClosures.removeAll()
        
        self.delegate.didInsertSectionClosures.removeAll()
        self.delegate.didDeleteSectionClosures.removeAll()
        self.delegate.didUpdateSectionClosures.removeAll()
        
        self.delegate.didInsertObjectClosures.removeAll()
        self.delegate.didDeleteObjectClosures.removeAll()
        self.delegate.didUpdateObjectClosures.removeAll()
        self.delegate.didMoveObjectClosures.removeAll()
        
        self.delegate.sectionIndexTitleClosure = nil
    }
    
}

extension FetchRequestController {
    
    public func refresh() throws {
        self.delegate.needsReloadDataClosure?()
        
        for closure in self.delegate.willChangeContentClosures {
            closure()
        }
        
        if let cacheName = self.cacheName {
            FetchRequestController.deleteCache(withName: cacheName)
        }
        
        try self.performFetch()
        
        for closure in self.delegate.didChangeContentClosures {
            closure()
        }
    }
    
}

extension FetchRequestController {
 
    @discardableResult
    internal func needsReloadData(closure: @escaping () -> Void) -> Self {
        self.delegate.needsReloadDataClosure = closure
        return self
    }

}

extension FetchRequestController {
    
    @discardableResult
    public func willChangeContent(closure: @escaping () -> Void) -> Self {
        self.delegate.willChangeContentClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didChangeContent(closure: @escaping () -> Void) -> Self {
        self.delegate.didChangeContentClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didInsertSection(closure: @escaping (FetchRequestControllerSection<T>, Int) -> Void) -> Self {
        self.delegate.didInsertSectionClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didDeleteSection(closure: @escaping (FetchRequestControllerSection<T>, Int) -> Void) -> Self {
        self.delegate.didDeleteSectionClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didUpdateSection(closure: @escaping (FetchRequestControllerSection<T>, Int) -> Void) -> Self {
        self.delegate.didUpdateSectionClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didInsertObject(closure: @escaping (T, IndexPath) -> Void) -> Self {
        self.delegate.didInsertObjectClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didDeleteObject(closure: @escaping (T, IndexPath) -> Void) -> Self {
        self.delegate.didDeleteObjectClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didUpdateObject(closure: @escaping (T, IndexPath) -> Void) -> Self {
        self.delegate.didUpdateObjectClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func didMoveObject(closure: @escaping (T, IndexPath, IndexPath) -> Void) -> Self {
        self.delegate.didMoveObjectClosures.append(closure)
        return self
    }
    
    @discardableResult
    public func sectionIndexTitle(closure: @escaping (String) -> String?) -> Self {
        self.delegate.sectionIndexTitleClosure = closure
        return self
    }
    
}
