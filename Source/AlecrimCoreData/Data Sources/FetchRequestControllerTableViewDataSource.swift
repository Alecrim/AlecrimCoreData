//
//  FetchRequestControllerTableViewDataSource.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-06-02.
//  Copyright © 2016 Alecrim. All rights reserved.
//

#if os(iOS)

import Foundation
import CoreData

public /* abstract */ class FetchRequestControllerTableViewDataSource<E: NSManagedObject>: TableViewDataSource {
    
    public final let fetchRequestController: FetchRequestController<E>
    
    public init(tableView: UITableView, fetchRequestController: FetchRequestController<E>) {
        self.fetchRequestController = fetchRequestController
        super.init(tableView: tableView)
    }
    
    //
    
    public final func section(atIndex sectionIndex: Int) -> FetchRequestControllerSection<E> {
        return self.fetchRequestController.sections[sectionIndex]
    }
    
    public final func entity(at indexPath: NSIndexPath) -> E {
        return self.fetchRequestController.entity(at: indexPath)
    }
    
    public final func indexPath(for entity: E) -> NSIndexPath? {
        return self.fetchRequestController.indexPath(for: entity)
    }
    
    // MARK: -
    
    public override final func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchRequestController.numberOfSections()
    }
    
    public override final func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchRequestController.numberOfEntities(inSection: section)
    }

    
}
extension FetchRequestControllerTableViewDataSource {
    
    public final func bind(with rowAnimation: UITableViewRowAnimation = .Fade) {
        self.fetchRequestController
            .willChangeContent { [unowned self] in
                self.beginUpdates()
            }
            .didInsertSection { [unowned self] sectionInfo, newSectionIndex in
                self.insertSections(NSIndexSet(index: newSectionIndex), with: rowAnimation)
            }
            .didDeleteSection { [unowned self] sectionInfo, sectionIndex in
                self.deleteSections(NSIndexSet(index: sectionIndex), with: rowAnimation)
            }
            .didUpdateSection { [unowned self] sectionInfo, sectionIndex in
                self.reloadSections(NSIndexSet(index: sectionIndex), with: rowAnimation)
            }
            .didInsertEntity { [unowned self] entity, newIndexPath in
                self.insertRows(at: [newIndexPath], with: rowAnimation)
            }
            .didDeleteEntity { [unowned self] entity, indexPath in
                self.deleteRows(at: [indexPath], with: rowAnimation)
            }
            .didUpdateEntity { [unowned self] entity, indexPath in
                self.reloadRows(at: [indexPath], with: rowAnimation)
            }
            .didMoveEntity { [unowned self] entity, indexPath, newIndexPath in
                self.moveRow(at: indexPath, to: newIndexPath)
            }
            .didChangeContent { [unowned self] in
                self.endUpdates()
        }
        
        try! self.fetchRequestController.performFetch()
    }
    
    private final func _bind(with rowAnimation: UITableViewRowAnimation = .Fade) {
        let insertedSectionIndexes = NSMutableIndexSet()
        let deletedSectionIndexes = NSMutableIndexSet()
        let updatedSectionIndexes = NSMutableIndexSet()
        
        var insertedItemIndexPaths = [NSIndexPath]()
        var deletedItemIndexPaths = [NSIndexPath]()
        var updatedItemIndexPaths = [NSIndexPath]()
        
        self.fetchRequestController
            .willChangeContent {
                insertedSectionIndexes.removeAllIndexes()
                deletedSectionIndexes.removeAllIndexes()
                updatedSectionIndexes.removeAllIndexes()
                
                insertedItemIndexPaths.removeAll(keepCapacity: false)
                deletedItemIndexPaths.removeAll(keepCapacity: false)
                updatedItemIndexPaths.removeAll(keepCapacity: false)
            }
            .didInsertSection { sectionInfo, newSectionIndex in
                insertedSectionIndexes.addIndex(newSectionIndex)
            }
            .didDeleteSection { sectionInfo, sectionIndex in
                deletedSectionIndexes.addIndex(sectionIndex)
                deletedItemIndexPaths = deletedItemIndexPaths.filter { $0.section != sectionIndex }
                updatedItemIndexPaths = updatedItemIndexPaths.filter { $0.section != sectionIndex }
            }
            .didUpdateSection { sectionInfo, sectionIndex in
                updatedSectionIndexes.addIndex(sectionIndex)
            }
            .didInsertEntity { entity, newIndexPath in
                if !insertedSectionIndexes.containsIndex(newIndexPath.section) {
                    insertedItemIndexPaths.append(newIndexPath)
                }
            }
            .didDeleteEntity { entity, indexPath in
                if !deletedSectionIndexes.containsIndex(indexPath.section) {
                    deletedItemIndexPaths.append(indexPath)
                }
            }
            .didUpdateEntity { entity, indexPath in
                if !deletedSectionIndexes.containsIndex(indexPath.section) && deletedItemIndexPaths.indexOf(indexPath) == nil && updatedItemIndexPaths.indexOf(indexPath) == nil {
                    updatedItemIndexPaths.append(indexPath)
                }
            }
            .didMoveEntity { entity, indexPath, newIndexPath in
                if newIndexPath == indexPath {
                    if !deletedSectionIndexes.containsIndex(indexPath.section) && deletedItemIndexPaths.indexOf(indexPath) == nil && updatedItemIndexPaths.indexOf(indexPath) == nil {
                        updatedItemIndexPaths.append(indexPath)
                    }
                }
                else {
                    if !deletedSectionIndexes.containsIndex(indexPath.section) {
                        deletedItemIndexPaths.append(indexPath)
                    }
                    
                    if !insertedSectionIndexes.containsIndex(newIndexPath.section) {
                        insertedItemIndexPaths.append(newIndexPath)
                    }
                }
            }
            .didChangeContent { [unowned self] in
                self.beginUpdates()
                
                if deletedSectionIndexes.count > 0 {
                    self.deleteSections(deletedSectionIndexes, with: rowAnimation)
                }
                
                if insertedSectionIndexes.count > 0 {
                    self.insertSections(insertedSectionIndexes, with: rowAnimation)
                }
                
                if updatedSectionIndexes.count > 0 {
                    self.reloadSections(updatedSectionIndexes, with: rowAnimation)
                }
                
                if deletedItemIndexPaths.count > 0 {
                    self.deleteRows(at: deletedItemIndexPaths, with: rowAnimation)
                }
                
                if insertedItemIndexPaths.count > 0 {
                    self.insertRows(at: insertedItemIndexPaths, with: rowAnimation)
                }
                
                if updatedItemIndexPaths.count > 0 {
                    self.reloadRows(at: updatedItemIndexPaths, with: rowAnimation)
                }
                
                self.endUpdates()
            }
        
        try! self.fetchRequestController.performFetch()
    }
    
}

#endif
