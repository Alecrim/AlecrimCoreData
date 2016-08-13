//
//  NSCollectionViewExtensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-28.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

#if os(OSX)
    
import Foundation
import AppKit
    
extension FetchRequestController {

    @available(OSX 10.11, *)
    public func bind<ItemType: NSCollectionViewItem>(to collectionView: NSCollectionView, sectionOffset: Int = 0, cellConfigurationHandler: ((ItemType, NSIndexPath) -> Void)? = nil) -> Self {
        let insertedSectionIndexes = NSMutableIndexSet()
        let deletedSectionIndexes = NSMutableIndexSet()
        let updatedSectionIndexes = NSMutableIndexSet()
        
        var insertedItemIndexPaths = [NSIndexPath]()
        var deletedItemIndexPaths = [NSIndexPath]()
        var updatedItemIndexPaths = [NSIndexPath]()
        
        var reloadData = false
        
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
                }
            }
            .didInsertSection { sectionInfo, sectionIndex in
                if !reloadData {
                    insertedSectionIndexes.addIndex(sectionIndex + sectionOffset)
                }
            }
            .didDeleteSection { sectionInfo, sectionIndex in
                if !reloadData {
                    deletedSectionIndexes.addIndex(sectionIndex + sectionOffset)
                    deletedItemIndexPaths = deletedItemIndexPaths.filter { $0.section != sectionIndex }
                    updatedItemIndexPaths = updatedItemIndexPaths.filter { $0.section != sectionIndex }
                }
            }
            .didInsertEntity { entity, newIndexPath in
                if !reloadData {
                    let newIndexPath = sectionOffset > 0 ? NSIndexPath(forItem: newIndexPath.item, inSection: newIndexPath.section + sectionOffset) : newIndexPath

                    if !insertedSectionIndexes.containsIndex(newIndexPath.section) {
                        insertedItemIndexPaths.append(newIndexPath)
                    }
                }
            }
            .didDeleteEntity { entity, indexPath in
                if !reloadData {
                    let indexPath = sectionOffset > 0 ? NSIndexPath(forItem: indexPath.item, inSection: indexPath.section + sectionOffset) : indexPath

                    if !deletedSectionIndexes.containsIndex(indexPath.section) {
                        deletedItemIndexPaths.append(indexPath)
                    }
                }
            }
            .didUpdateEntity { entity, indexPath in
                if !reloadData {
                    let indexPath = sectionOffset > 0 ? NSIndexPath(forItem: indexPath.item, inSection: indexPath.section + sectionOffset) : indexPath

                    if !deletedSectionIndexes.containsIndex(indexPath.section) && deletedItemIndexPaths.indexOf(indexPath) == nil && updatedItemIndexPaths.indexOf(indexPath) == nil {
                        updatedItemIndexPaths.append(indexPath)
                    }
                }
            }
            .didMoveEntity { entity, indexPath, newIndexPath in
                if !reloadData {
                    let newIndexPath = sectionOffset > 0 ? NSIndexPath(forItem: newIndexPath.item, inSection: newIndexPath.section + sectionOffset) : newIndexPath
                    let indexPath = sectionOffset > 0 ? NSIndexPath(forItem: indexPath.item, inSection: indexPath.section + sectionOffset) : indexPath

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
            }
            .didChangeContent { [unowned collectionView] in
                if reloadData {
                    collectionView.reloadData()
                    
                    insertedSectionIndexes.removeAllIndexes()
                    deletedSectionIndexes.removeAllIndexes()
                    updatedSectionIndexes.removeAllIndexes()
                    
                    insertedItemIndexPaths.removeAll(keepCapacity: false)
                    deletedItemIndexPaths.removeAll(keepCapacity: false)
                    updatedItemIndexPaths.removeAll(keepCapacity: false)
                    
                    reloadData = false
                }
                else {
                    collectionView.performBatchUpdates({
                        if deletedSectionIndexes.count > 0 {
                            collectionView.deleteSections(deletedSectionIndexes)
                        }
                        
                        if insertedSectionIndexes.count > 0 {
                            collectionView.insertSections(insertedSectionIndexes)
                        }
                        
                        if updatedSectionIndexes.count > 0 {
                            collectionView.reloadSections(updatedSectionIndexes)
                        }
                        
                        if deletedItemIndexPaths.count > 0 {
                            collectionView.deleteItemsAtIndexPaths(Set(deletedItemIndexPaths))
                        }
                        
                        if insertedItemIndexPaths.count > 0 {
                            collectionView.insertItemsAtIndexPaths(Set(insertedItemIndexPaths))
                        }
                        
                        if updatedItemIndexPaths.count > 0 && cellConfigurationHandler == nil {
                            collectionView.reloadItemsAtIndexPaths(Set(updatedItemIndexPaths))
                        }
                        },
                        completionHandler: { finished in
                            if finished {
                                if let cellConfigurationHandler = cellConfigurationHandler {
                                    for updatedItemIndexPath in updatedItemIndexPaths {
                                        if let item = collectionView.itemAtIndexPath(updatedItemIndexPath) as? ItemType {
                                            cellConfigurationHandler(item, updatedItemIndexPath)
                                        }
                                    }
                                }
                                
                                insertedSectionIndexes.removeAllIndexes()
                                deletedSectionIndexes.removeAllIndexes()
                                updatedSectionIndexes.removeAllIndexes()
                                
                                insertedItemIndexPaths.removeAll(keepCapacity: false)
                                deletedItemIndexPaths.removeAll(keepCapacity: false)
                                updatedItemIndexPaths.removeAll(keepCapacity: false)
                                
                                reloadData = false
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
