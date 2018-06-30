//
//  FetchedResultsControllerDelegate.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 12/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// MARK: -

public final class FetchedResultsControllerDelegate<Entity: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {

    // MARK: -
    
    internal typealias NeedsReloadDataClosure = () -> Void
    public typealias ChangeContentClosure = () -> Void
    public typealias ChangeSectionClosure = (FetchedResultsSectionInfo<Entity>, Int) -> Void
    public typealias ChangeItemClosure = (Entity, IndexPath) -> Void
    public typealias MoveItemClosure = (Entity, IndexPath, IndexPath) -> Void
    public typealias SectionIndexTitleClosure = (String) -> String?

    // MARK: -
    
    fileprivate var needsReloadDataClosure: NeedsReloadDataClosure?
    
    fileprivate lazy var willChangeContentClosuresContainer = ClosuresContainer<ChangeContentClosure>()
    fileprivate lazy var didChangeContentClosuresContainer = ClosuresContainer<ChangeContentClosure>()
    
    fileprivate lazy var didInsertSectionClosuresContainer = ClosuresContainer<ChangeSectionClosure>()
    fileprivate lazy var didDeleteSectionClosuresContainer = ClosuresContainer<ChangeSectionClosure>()

    fileprivate lazy var didInsertObjectClosuresContainer = ClosuresContainer<ChangeItemClosure>()
    fileprivate lazy var didDeleteObjectClosuresContainer = ClosuresContainer<ChangeItemClosure>()
    fileprivate lazy var didUpdateObjectClosuresContainer = ClosuresContainer<ChangeItemClosure>()
    fileprivate lazy var didMoveObjectClosuresContainer = ClosuresContainer<MoveItemClosure>()

    fileprivate var sectionIndexTitleClosure: SectionIndexTitleClosure?

    // MARK: -
    
    public func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.willChangeContentClosuresContainer.closures.forEach { $0() }
    }
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let sectionInfo = FetchedResultsSectionInfo<Entity>(rawValue: sectionInfo)
        
        switch type {
        case .insert:
            self.didInsertSectionClosuresContainer.closures.forEach { $0(sectionInfo, sectionIndex) }
            
        case .delete:
            self.didDeleteSectionClosuresContainer.closures.forEach { $0(sectionInfo, sectionIndex) }

        default:
            break
        }
    }
    
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            self.didInsertObjectClosuresContainer.closures.forEach { $0(anObject as! Entity, newIndexPath!) }

        case .delete:
            self.didDeleteObjectClosuresContainer.closures.forEach { $0(anObject as! Entity, indexPath!) }

        case .update:
            self.didUpdateObjectClosuresContainer.closures.forEach { $0(anObject as! Entity, indexPath!) }

        case .move:
            self.didMoveObjectClosuresContainer.closures.forEach { $0(anObject as! Entity, indexPath!, newIndexPath!) }
        }
    }
    
    
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.didChangeContentClosuresContainer.closures.forEach { $0() }
    }
    
    
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return self.sectionIndexTitleClosure?(sectionName)
    }
    
    
}

// MARK: -

public final class ClosuresContainer<Closure> {
    
    fileprivate lazy var closures = [Closure]()
    
    internal func removeAll() {
        self.closures.removeAll()
    }
    
}

public func +=<Closure>(left: ClosuresContainer<Closure>, right: Closure) {
    left.closures.append(right)
}


// MARK: - FetchRequestController extensions

extension FetchRequestController {
    
    public func removeAllBindings() {
        self.rawValueDelegate.needsReloadDataClosure = nil
        
        self.rawValueDelegate.willChangeContentClosuresContainer.removeAll()
        self.rawValueDelegate.didChangeContentClosuresContainer.removeAll()
        
        self.rawValueDelegate.didInsertSectionClosuresContainer.removeAll()
        self.rawValueDelegate.didDeleteSectionClosuresContainer.removeAll()
        
        self.rawValueDelegate.didInsertObjectClosuresContainer.removeAll()
        self.rawValueDelegate.didDeleteObjectClosuresContainer.removeAll()
        self.rawValueDelegate.didUpdateObjectClosuresContainer.removeAll()
        self.rawValueDelegate.didMoveObjectClosuresContainer.removeAll()
        
        self.rawValueDelegate.sectionIndexTitleClosure = nil
    }
    
}

extension FetchRequestController {
    
    public func refresh() {
        self.rawValueDelegate.needsReloadDataClosure?()

        self.rawValueDelegate.willChangeContentClosuresContainer.closures.forEach { $0() }

        if let cacheName = self.rawValue.cacheName {
            NSFetchedResultsController<NSFetchRequestResult>.deleteCache(withName: cacheName)
        }

        self.performFetch()

        self.rawValueDelegate.didChangeContentClosuresContainer.closures.forEach { $0() }
    }
    
}

extension FetchRequestController {
    
    @discardableResult
    internal func needsReloadData(closure: @escaping FetchedResultsControllerDelegate<Entity>.NeedsReloadDataClosure) -> Self {
        self.rawValueDelegate.needsReloadDataClosure = closure
        return self
    }
    
}

extension FetchRequestController {

    @discardableResult
    public func willChangeContent(closure: @escaping FetchedResultsControllerDelegate<Entity>.ChangeContentClosure) -> Self {
        self.rawValueDelegate.willChangeContentClosuresContainer += closure
        return self
    }
    
    @discardableResult
    public func didChangeContent(closure: @escaping FetchedResultsControllerDelegate<Entity>.ChangeContentClosure) -> Self {
        self.rawValueDelegate.didChangeContentClosuresContainer += closure
        return self
    }

    @discardableResult
    public func didInsertSection(closure: @escaping FetchedResultsControllerDelegate<Entity>.ChangeSectionClosure) -> Self {
        self.rawValueDelegate.didInsertSectionClosuresContainer += closure
        return self
    }
    
    @discardableResult
    public func didDeleteSection(closure: @escaping FetchedResultsControllerDelegate<Entity>.ChangeSectionClosure) -> Self {
        self.rawValueDelegate.didDeleteSectionClosuresContainer += closure
        return self
    }
    
    @discardableResult
    public func didInsertObject(closure: @escaping FetchedResultsControllerDelegate<Entity>.ChangeItemClosure) -> Self {
        self.rawValueDelegate.didInsertObjectClosuresContainer += closure
        return self
    }
    
    @discardableResult
    public func didDeleteObject(closure: @escaping FetchedResultsControllerDelegate<Entity>.ChangeItemClosure) -> Self {
        self.rawValueDelegate.didDeleteObjectClosuresContainer += closure
        return self
    }
    
    @discardableResult
    public func didUpdateObject(closure: @escaping FetchedResultsControllerDelegate<Entity>.ChangeItemClosure) -> Self {
        self.rawValueDelegate.didUpdateObjectClosuresContainer += closure
        return self
    }
    
    @discardableResult
    public func didMoveObject(closure: @escaping FetchedResultsControllerDelegate<Entity>.MoveItemClosure) -> Self {
        self.rawValueDelegate.didMoveObjectClosuresContainer += closure
        return self
    }
    
    @discardableResult
    public func sectionIndexTitle(closure: @escaping FetchedResultsControllerDelegate<Entity>.SectionIndexTitleClosure) -> Self {
        self.rawValueDelegate.sectionIndexTitleClosure = closure
        return self
    }

}
