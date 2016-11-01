//
//  NSCollectionViewExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

#if os(macOS)
    
    import Foundation
    import AppKit
    
    extension FetchRequestController {
        
        @discardableResult
        public func bind<ItemType: NSCollectionViewItem>(to collectionView: NSCollectionView, sectionOffset: Int = 0, cellConfigurationHandler: ((ItemType, IndexPath) -> Void)? = nil) -> Self {
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
                        deletedItemIndexPaths = deletedItemIndexPaths.filter { $0.section != sectionIndex }
                        updatedItemIndexPaths = updatedItemIndexPaths.filter { $0.section != sectionIndex }
                    }
                }
                .didUpdateSection { sectionInfo, sectionIndex in
                    if !reloadData {
                        updatedSectionIndexes.add(sectionIndex + sectionOffset)
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
                .didChangeContent { [weak collectionView] in
                    //
                    guard let collectionView = collectionView else {
                        reset()
                        return
                    }
                    
                    //
                    if reloadData {
                        collectionView.reloadData()
                        reset()
                    }
                    else {
                        collectionView.performBatchUpdates({
                            if deletedSectionIndexes.count > 0 {
                                collectionView.deleteSections(deletedSectionIndexes as IndexSet)
                            }
                            
                            if insertedSectionIndexes.count > 0 {
                                collectionView.insertSections(insertedSectionIndexes as IndexSet)
                            }
                            
                            if updatedSectionIndexes.count > 0 {
                                collectionView.reloadSections(updatedSectionIndexes as IndexSet)
                            }
                            
                            if deletedItemIndexPaths.count > 0 {
                                collectionView.deleteItems(at: Set(deletedItemIndexPaths))
                            }
                            
                            if insertedItemIndexPaths.count > 0 {
                                collectionView.insertItems(at: Set(insertedItemIndexPaths))
                            }
                            
                            if updatedItemIndexPaths.count > 0 && cellConfigurationHandler == nil {
                                collectionView.reloadItems(at: Set(updatedItemIndexPaths))
                            }
                        }, completionHandler: { finished in
                            if finished {
                                if let cellConfigurationHandler = cellConfigurationHandler {
                                    for updatedItemIndexPath in updatedItemIndexPaths {
                                        if let item = collectionView.item(at: updatedItemIndexPath) as? ItemType {
                                            cellConfigurationHandler(item, updatedItemIndexPath)
                                        }
                                    }
                                }
                                
                                reset()
                            }
                        })
                    }
            }
            
            //
            try! self.performFetch()
            collectionView.reloadData()
            
            //
            return self
        }
        
    }
    
#endif
