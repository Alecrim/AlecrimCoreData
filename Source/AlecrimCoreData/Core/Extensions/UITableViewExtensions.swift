//
//  UITableViewExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

#if os(iOS) || os(tvOS)
    
    import Foundation
    import UIKit
    
    extension FetchRequestController {
        
        @discardableResult
        public func bind<CellType: UITableViewCell>(to tableView: UITableView, rowAnimation: UITableViewRowAnimation = .fade, sectionOffset: Int = 0, cellConfigurationHandler: ((CellType, IndexPath) -> Void)? = nil) -> Self {
            let insertedSectionIndexes = NSMutableIndexSet()
            let deletedSectionIndexes = NSMutableIndexSet()
            let updatedSectionIndexes = NSMutableIndexSet()
            
            var insertedItemIndexPaths = [IndexPath]()
            var deletedItemIndexPaths = [IndexPath]()
            var updatedItemIndexPaths = [IndexPath]()
            
            var reloadData = false
            
            //
            func reset() {
                insertedSectionIndexes.removeAllIndexes()
                deletedSectionIndexes.removeAllIndexes()
                updatedSectionIndexes.removeAllIndexes()
                
                insertedItemIndexPaths.removeAll(keepingCapacity: false)
                deletedItemIndexPaths.removeAll(keepingCapacity: false)
                updatedItemIndexPaths.removeAll(keepingCapacity: false)
                
                reloadData = false
            }
            
            //
            self
                .needsReloadData {
                    reloadData = true
                }
                .willChangeContent {
                    if !reloadData {
                        //
                        reset()
                    }
                }
                .didInsertSection { sectionInfo, sectionIndex in
                    if !reloadData {
                        insertedSectionIndexes.add(sectionIndex + sectionOffset)
                    }
                }
                .didDeleteSection { sectionInfo, sectionIndex in
                    if !reloadData {
                        deletedSectionIndexes.add(sectionIndex + sectionOffset)
                        deletedItemIndexPaths = deletedItemIndexPaths.filter { $0.section != sectionIndex}
                        updatedItemIndexPaths = updatedItemIndexPaths.filter { $0.section != sectionIndex}
                    }
                }
                .didUpdateSection { sectionInfo, sectionIndex in
                    if !reloadData {
                        updatedSectionIndexes.add(sectionIndex + sectionOffset)
                    }
                }
                .didInsertObject { entity, newIndexPath in
                    if !reloadData {
                        let newIndexPath = sectionOffset > 0 ? IndexPath(row: newIndexPath.item, section: newIndexPath.section + sectionOffset) : newIndexPath
                        
                        if !insertedSectionIndexes.contains(newIndexPath.section) {
                            insertedItemIndexPaths.append(newIndexPath)
                        }
                    }
                }
                .didDeleteObject { entity, indexPath in
                    if !reloadData {
                        let indexPath = sectionOffset > 0 ? IndexPath(row: indexPath.item, section: indexPath.section + sectionOffset) : indexPath
                        
                        if !deletedSectionIndexes.contains(indexPath.section) {
                            deletedItemIndexPaths.append(indexPath)
                        }
                    }
                }
                .didUpdateObject { entity, indexPath in
                    if !reloadData {
                        let indexPath = sectionOffset > 0 ? IndexPath(row: indexPath.item, section: indexPath.section + sectionOffset) : indexPath
                        
                        if !deletedSectionIndexes.contains(indexPath.section) && deletedItemIndexPaths.index(of: indexPath) == nil && updatedItemIndexPaths.index(of: indexPath) == nil {
                            updatedItemIndexPaths.append(indexPath)
                        }
                    }
                }
                .didMoveObject { entity, indexPath, newIndexPath in
                    if !reloadData {
                        let newIndexPath = sectionOffset > 0 ? IndexPath(row: newIndexPath.item, section: newIndexPath.section + sectionOffset) : newIndexPath
                        let indexPath = sectionOffset > 0 ? IndexPath(row: indexPath.item, section: indexPath.section + sectionOffset) : indexPath
                        
                        if newIndexPath == indexPath {
                            if !deletedSectionIndexes.contains(indexPath.section) && deletedItemIndexPaths.index(of: indexPath) == nil && updatedItemIndexPaths.index(of: indexPath) == nil {
                                updatedItemIndexPaths.append(indexPath)
                            }
                        }
                        else {
                            if !deletedSectionIndexes.contains(indexPath.section) {
                                deletedItemIndexPaths.append(indexPath)
                            }
                            
                            if !insertedSectionIndexes.contains(newIndexPath.section) {
                                insertedItemIndexPaths.append(newIndexPath)
                            }
                        }
                    }
                }
                .didChangeContent { [weak tableView] in
                    //
                    defer { reset() }

                    //
                    guard let tableView = tableView else {
                        return
                    }

                    //
                    if reloadData {
                        tableView.reloadData()
                    }
                    else {
                        tableView.beginUpdates()
                        
                        if deletedSectionIndexes.count > 0 {
                            tableView.deleteSections(deletedSectionIndexes as IndexSet, with: rowAnimation)
                        }
                        
                        if insertedSectionIndexes.count > 0 {
                            tableView.insertSections(insertedSectionIndexes as IndexSet, with: rowAnimation)
                        }
                        
                        if updatedSectionIndexes.count > 0 {
                            tableView.reloadSections(updatedSectionIndexes as IndexSet, with: rowAnimation)
                        }
                        
                        if deletedItemIndexPaths.count > 0 {
                            tableView.deleteRows(at: deletedItemIndexPaths, with: rowAnimation)
                        }
                        
                        if insertedItemIndexPaths.count > 0 {
                            tableView.insertRows(at: insertedItemIndexPaths, with: rowAnimation)
                        }
                        
                        if updatedItemIndexPaths.count > 0 && cellConfigurationHandler == nil {
                            tableView.reloadRows(at: updatedItemIndexPaths, with: rowAnimation)
                        }
                        
                        tableView.endUpdates()
                        
                        if let cellConfigurationHandler = cellConfigurationHandler {
                            for updatedItemIndexPath in updatedItemIndexPaths {
                                if let cell = tableView.cellForRow(at: updatedItemIndexPath) as? CellType {
                                    cellConfigurationHandler(cell, updatedItemIndexPath)
                                }
                            }
                        }
                    }
            }
            
            //
            try! self.performFetch()
            tableView.reloadData()
            
            //
            return self
        }
        
    }
    
#endif
