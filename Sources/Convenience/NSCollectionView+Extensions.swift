//
//  NSCollectionView+Extensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

#if os(macOS)

import Foundation
import AppKit

extension FetchRequestController {

    /// WARNING: To avoid memory leaks do not pass a func as the configuration handler, pass a closure with *weak* self.
    @discardableResult
    public func bind(to collectionView: NSCollectionView, sectionOffset: Int = 0, animated: Bool = false, itemConfigurationHandler: ((NSCollectionViewItem, IndexPath) -> Void)? = nil) -> Self {
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
                if collectionView.numberOfSections == 0 {
                    reloadData = true
                }

                guard !reloadData else { return }
                reset()
            }
            .didInsertSection { _, sectionIndex in
                guard !reloadData else { return }
                sectionChanges.append(.insert(sectionIndex))
            }
            .didDeleteSection { _, sectionIndex in
                guard !reloadData else { return }
                sectionChanges.append(.delete(sectionIndex))
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
            .didChangeContent { [weak collectionView] in
                //
                guard let collectionView = collectionView else {
                    reset()
                    return
                }

                //
                guard !reloadData else {
                    collectionView.reloadData()
                    reset()
                    return
                }

                //
                var updatedIndexPaths = [IndexPath]()

                let performer = animated ? collectionView.animator() : collectionView

                performer.performBatchUpdates({
                    sectionChanges.forEach {
                        switch $0 {
                        case .insert(let sectionIndex):
                            collectionView.insertSections(IndexSet(integer: sectionIndex))

                        case .delete(let sectionIndex):
                            collectionView.deleteSections(IndexSet(integer: sectionIndex))

                        default:
                            break
                        }
                    }

                    itemChanges.forEach {
                        switch $0 {
                        case .insert(let indexPath):
                            collectionView.insertItems(at: Set([indexPath]))

                        case .delete(let indexPath):
                            collectionView.deleteItems(at: Set([indexPath]))

                        case .update(let indexPath):
                            if itemConfigurationHandler == nil {
                                collectionView.reloadItems(at: Set([indexPath]))
                            }
                            else {
                                updatedIndexPaths.append(indexPath)
                            }

                        case .move(let oldIndexPath, let newIndexPath):
                            collectionView.moveItem(at: oldIndexPath, to: newIndexPath)

                            // workaround to be sure that cells will be refreshed
                            // note: this only works when using a cell configuration handler
                            if itemConfigurationHandler != nil {
                                updatedIndexPaths.append(newIndexPath)
                            }
                        }
                    }
                }, completionHandler: { _ in
                    updatedIndexPaths.forEach {
                        if let item = collectionView.item(at: $0) {
                            itemConfigurationHandler?(item, $0)
                        }
                    }

                    reset()
                })
        }

        //
        collectionView.reloadData()

        //
        return self
    }

}

#endif




