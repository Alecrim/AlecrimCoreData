//
//  UITableViewExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

#if os(iOS)
    
import Foundation
import UIKit
    
extension FetchRequestController {

    public func bindToTableView(tableView: UITableView, rowAnimation: UITableViewRowAnimation = .Fade, reloadRowAtIndexPath reloadRowAtIndexPathClosure: (NSIndexPath -> Void)? = nil) -> Self {
        let insertedSectionIndexes = NSMutableIndexSet()
        let deletedSectionIndexes = NSMutableIndexSet()
        let updatedSectionIndexes = NSMutableIndexSet()
        
        var insertedItemIndexPaths = [NSIndexPath]()
        var deletedItemIndexPaths = [NSIndexPath]()
        var updatedItemIndexPaths = [NSIndexPath]()
        
        var reloadData = false
        
        //
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
                    if !deletedSectionIndexes.containsIndex(indexPath.section) && deletedItemIndexPaths.indexOf(indexPath) == nil && updatedItemIndexPaths.indexOf(indexPath) == nil {
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
        
        //
        try! self.performFetch()
        tableView.reloadData()

        //
        return self
    }
        
}

#endif
