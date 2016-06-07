//
//  FetchRequestControllerCollectionViewDataSource.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-06-02.
//  Copyright © 2016 Alecrim. All rights reserved.
//

#if os(iOS)

import Foundation
import CoreData

public /* abstract */ class FetchRequestControllerCollectionViewDataSource<E: NSManagedObject>: CollectionViewDataSource {
    
    public final let fetchRequestController: FetchRequestController<E>
    
    public init(collectionView: UICollectionView, fetchRequestController: FetchRequestController<E>) {
        self.fetchRequestController = fetchRequestController
        super.init(collectionView: collectionView)
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
    
    public override final func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchRequestController.numberOfSections()
    }
    
    public override final func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchRequestController.numberOfEntities(inSection: section)
    }

    
}
extension FetchRequestControllerCollectionViewDataSource {
    
    public final func bind() {
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
                self.performBatchUpdates(
                    {
                        if deletedSectionIndexes.count > 0 {
                            self.deleteSections(deletedSectionIndexes)
                        }
                        
                        if insertedSectionIndexes.count > 0 {
                            self.insertSections(insertedSectionIndexes)
                        }
                        
                        if updatedSectionIndexes.count > 0 {
                            self.reloadSections(updatedSectionIndexes)
                        }
                        
                        if deletedItemIndexPaths.count > 0 {
                            self.deleteItems(at: deletedItemIndexPaths)
                        }
                        
                        if insertedItemIndexPaths.count > 0 {
                            self.insertItems(at: insertedItemIndexPaths)
                        }
                        
                        if updatedItemIndexPaths.count > 0 {
                            self.reloadItems(at: updatedItemIndexPaths)
                        }
                    },
                    completion: { finished in
                        if finished {
                            insertedSectionIndexes.removeAllIndexes()
                            deletedSectionIndexes.removeAllIndexes()
                            updatedSectionIndexes.removeAllIndexes()
                            
                            insertedItemIndexPaths.removeAll(keepCapacity: false)
                            deletedItemIndexPaths.removeAll(keepCapacity: false)
                            updatedItemIndexPaths.removeAll(keepCapacity: false)
                        }
                })
        }
        
        try! self.fetchRequestController.performFetch()
    }
    
}

#endif
