//
//  NSTableView+Extensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 04/04/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

#if os(macOS)

import Foundation
import Cocoa

extension FetchRequestController {

    /// WARNING: To avoid memory leaks do not pass a func as the configuration handler, pass a closure with *weak* self.
    @discardableResult
    public func bind(to tableView: NSTableView, animationOptions: NSTableView.AnimationOptions = .effectFade, sectionOffset: Int = 0, cellViewConfigurationHandler: ((NSTableCellView, IndexPath) -> Void)? = nil) -> Self {
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
            .didInsertObject { entity, newIndexPath in
                if !reloadData {
                    let newIndexPath = sectionOffset > 0 ? IndexPath(item: newIndexPath.item, section: newIndexPath.section + sectionOffset) : newIndexPath

                    if !insertedSectionIndexes.contains(newIndexPath.section) {
                        insertedItemIndexPaths.append(newIndexPath)
                    }
                }
            }
            .didDeleteObject { entity, indexPath in
                if !reloadData {
                    let indexPath = sectionOffset > 0 ? IndexPath(item: indexPath.item, section: indexPath.section + sectionOffset) : indexPath

                    if !deletedSectionIndexes.contains(indexPath.section) {
                        deletedItemIndexPaths.append(indexPath)
                    }
                }
            }
            .didUpdateObject { entity, indexPath in
                if !reloadData {
                    let indexPath = sectionOffset > 0 ? IndexPath(item: indexPath.item, section: indexPath.section + sectionOffset) : indexPath

                    if !deletedSectionIndexes.contains(indexPath.section) && deletedItemIndexPaths.index(of: indexPath) == nil && updatedItemIndexPaths.index(of: indexPath) == nil {
                        updatedItemIndexPaths.append(indexPath)
                    }
                }
            }
            .didMoveObject { entity, indexPath, newIndexPath in
                if !reloadData {
                    let newIndexPath = sectionOffset > 0 ? IndexPath(item: newIndexPath.item, section: newIndexPath.section + sectionOffset) : newIndexPath
                    let indexPath = sectionOffset > 0 ? IndexPath(item: indexPath.item, section: indexPath.section + sectionOffset) : indexPath

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

                    //                    if deletedSectionIndexes.count > 0 {
                    //                        tableView.deleteSections(deletedSectionIndexes as IndexSet, with: animationOptions)
                    //                    }

                    //                    if insertedSectionIndexes.count > 0 {
                    //                        tableView.insertSections(insertedSectionIndexes as IndexSet, with: animationOptions)
                    //                    }

                    //                    if updatedSectionIndexes.count > 0 {
                    //                        tableView.reloadSections(updatedSectionIndexes as IndexSet, with: animationOptions)
                    //                    }

                    if deletedItemIndexPaths.count > 0 {
                        let deletedRowsIndexSet = IndexSet(deletedItemIndexPaths.map { $0.item })
                        tableView.removeRows(at: deletedRowsIndexSet, withAnimation: animationOptions)
                    }

                    if insertedItemIndexPaths.count > 0 {
                        let insertedRowsIndexSet = IndexSet(insertedItemIndexPaths.map { $0.item })
                        tableView.insertRows(at: insertedRowsIndexSet, withAnimation: animationOptions)
                    }

                    tableView.endUpdates()

                    if updatedItemIndexPaths.count > 0 && cellViewConfigurationHandler == nil {
                        let updatedItemIndexSet = IndexSet(updatedItemIndexPaths.map { $0.item })
                        tableView.reloadData(forRowIndexes: updatedItemIndexSet, columnIndexes: IndexSet())
                    }

                    if let cellViewConfigurationHandler = cellViewConfigurationHandler {
                        for updatedItemIndexPath in updatedItemIndexPaths {
                            if let cell = tableView.view(atColumn: 0, row: updatedItemIndexPath.item, makeIfNecessary: false) as? NSTableCellView {
                                cellViewConfigurationHandler(cell, updatedItemIndexPath)
                            }
                        }
                    }
                }
        }

        //
        tableView.reloadData()

        //
        return self
    }

}

#endif


