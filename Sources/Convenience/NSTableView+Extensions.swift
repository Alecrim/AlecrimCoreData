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
    public func bind(to tableView: NSTableView, animationOptions: NSTableView.AnimationOptions = .effectFade, sectionOffset: Int = 0, animated: Bool = false, cellViewConfigurationHandler: ((NSTableCellView, IndexPath) -> Void)? = nil) -> Self {
        //
        var reloadData = false
        var sectionChanges = Array<Change<Int>>()
        var itemChanges = Array<Change<IndexPath>>()

        //
        func reset() {
            reloadData = false
            sectionChanges.removeAll()
            itemChanges.removeAll()
        }

        //
        self
            .needsReloadData {
                reloadData = true
            }
            .willChangeContent {
                if tableView.numberOfRows == 0 {
                    reloadData = true
                }

                guard !reloadData else { return }
                reset()
            }
            .didInsertSection { _, sectionIndex in
                reloadData = true
            }
            .didDeleteSection { _, sectionIndex in
                reloadData = true
            }
            .didInsertObject { _, newIndexPath in
                guard !reloadData else { return }

                let newIndexPath = sectionOffset > 0 ? IndexPath(item: newIndexPath.item, section: newIndexPath.section + sectionOffset) : newIndexPath
                itemChanges.append(.insert(newIndexPath))
            }
            .didDeleteObject { _, indexPath in
                guard !reloadData else { return }

                let indexPath = sectionOffset > 0 ? IndexPath(item: indexPath.item, section: indexPath.section + sectionOffset) : indexPath
                itemChanges.append(.delete(indexPath))
            }
            .didUpdateObject { _, indexPath in
                guard !reloadData else { return }

                let indexPath = sectionOffset > 0 ? IndexPath(item: indexPath.item, section: indexPath.section + sectionOffset) : indexPath
                itemChanges.append(.update(indexPath))
            }
            .didMoveObject { entity, indexPath, newIndexPath in
                guard !reloadData else { return }

                let indexPath = sectionOffset > 0 ? IndexPath(item: indexPath.item, section: indexPath.section + sectionOffset) : indexPath
                let newIndexPath = sectionOffset > 0 ? IndexPath(item: newIndexPath.item, section: newIndexPath.section + sectionOffset) : newIndexPath

                itemChanges.append(.move(indexPath, newIndexPath))
            }
            .didChangeContent { [weak tableView] in
                //
                defer { reset() }

                //
                guard let tableView = tableView else {
                    return
                }

                //
                guard !reloadData else {
                    tableView.reloadData()
                    return
                }

                //
                let performer = animated ? tableView.animator() : tableView

                //
                performer.beginUpdates()

                //
                var updatedIndexPaths = [IndexPath]()

                itemChanges.forEach {
                    switch $0 {
                    case .update(let indexPath):
                        if cellViewConfigurationHandler == nil {
                            performer.reloadData(forRowIndexes: IndexSet(integer: indexPath.item), columnIndexes: IndexSet())
                        }
                        else {
                            updatedIndexPaths.append(indexPath)
                        }

                    case .delete(let indexPath):
                        performer.removeRows(at: IndexSet(integer: indexPath.item), withAnimation: animationOptions)

                    case .insert(let indexPath):
                        performer.insertRows(at: IndexSet(integer: indexPath.item), withAnimation: animationOptions)

                    case .move(let oldIndexPath, let newIndexPath):
                        //performer.moveRow(at: oldIndexPath.item, to: newIndexPath.item)
                        performer.removeRows(at: IndexSet(integer: oldIndexPath.item), withAnimation: animationOptions)
                        performer.insertRows(at: IndexSet(integer: newIndexPath.item), withAnimation: animationOptions)
                    }
                }

                //
                performer.endUpdates()

                //
                updatedIndexPaths.forEach {
                    if let item = tableView.view(atColumn: 0, row: $0.item, makeIfNecessary: false) as? NSTableCellView {
                        cellViewConfigurationHandler?(item, $0)
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



