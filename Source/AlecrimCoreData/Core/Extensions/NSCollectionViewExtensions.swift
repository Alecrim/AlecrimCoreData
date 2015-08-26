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
    public func bindToCollectionView(collectionView: NSCollectionView, reloadItemAtIndexPath reloadItemAtIndexPathClosure: (NSIndexPath -> Void)? = nil) -> Self {
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
                    insertedSectionIndexes.addIndex(sectionIndex)
                }
            }
            .didDeleteSection { sectionInfo, sectionIndex in
                // TODO: find out more info about the NSCollectionView issue about section deletions
                reloadData = true
                
                //                if !reloadData {
                //                    deletedSectionIndexes.addIndex(sectionIndex)
                //                    deletedItemIndexPaths = deletedItemIndexPaths.filter { $0.section != sectionIndex }
                //                    updatedItemIndexPaths = updatedItemIndexPaths.filter { $0.section != sectionIndex }
                //                }
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
                        
                        if updatedItemIndexPaths.count > 0 && reloadItemAtIndexPathClosure == nil {
                            collectionView.reloadItemsAtIndexPaths(Set(updatedItemIndexPaths))
                        }
                        },
                        completionHandler: { finished in
                            if finished {
                                if let reloadItemAtIndexPathClosure = reloadItemAtIndexPathClosure {
                                    for updatedItemIndexPath in updatedItemIndexPaths {
                                        reloadItemAtIndexPathClosure(updatedItemIndexPath)
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
