//
//  DataSource+UICollectionView.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-06-01.
//  Copyright © 2016 Alecrim. All rights reserved.
//

#if os(iOS)
    
    import Foundation
    import UIKit
    
    extension UICollectionView: Container {
    }
    
    extension UICollectionViewCell: ContainerCell {
    }
    
    extension DataSource where T: UICollectionView {
        
        //
        
        public final func registerCellClass<ReusableCellType: UICollectionViewCell>(cellClass: ReusableCellType.Type) {
            self.container.registerClass(cellClass, forCellWithReuseIdentifier: String(cellClass))
        }
        
        public final func registerHeaderViewClass<ReusableHeaderViewType: UICollectionReusableView>(headerViewClass: ReusableHeaderViewType.Type) {
            self.container.registerClass(headerViewClass, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: String(headerViewClass))
        }
        
        public final func registerFooterViewClass<ReusableFooterViewType: UICollectionReusableView>(footerViewClass: ReusableFooterViewType.Type) {
            self.container.registerClass(footerViewClass, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: String(footerViewClass))
        }
        
        //
        
        public final func registerCellNib<ReusableCellType: UITableViewCell>(with cellClass: ReusableCellType.Type, bundle: NSBundle? = nil) {
            self.registerCellNib(withName: String(cellClass), bundle: bundle)
        }
        
        public final func registerHeaderViewNib<ReusableHeaderViewType: UITableViewHeaderFooterView>(with headerViewClass: ReusableHeaderViewType.Type, bundle: NSBundle? = nil) {
            self.registerHeaderViewNib(withName: String(headerViewClass), bundle: bundle)
        }
        
        public final func registerFooterViewNib<ReusableFooterViewType: UITableViewHeaderFooterView>(with footerViewClass: ReusableFooterViewType.Type, bundle: NSBundle? = nil) {
            self.registerFooterViewNib(withName: String(footerViewClass), bundle: bundle)
        }
        
        //
        
        public final func registerCellNib(withName nibName: String, bundle: NSBundle? = nil) {
            self.registerCellNib(UINib(nibName: nibName, bundle: bundle), reuseIdentifier: nibName)
        }
        
        public final func registerHeaderViewNib(withName nibName: String, bundle: NSBundle? = nil) {
            self.registerHeaderViewNib(UINib(nibName: nibName, bundle: bundle), reuseIdentifier: nibName)
        }
        
        public final func registerFooterViewNib(withName nibName: String, bundle: NSBundle? = nil) {
            self.registerFooterViewNib(UINib(nibName: nibName, bundle: bundle), reuseIdentifier: nibName)
        }
        
        //
        
        public final func registerCellNib(nib: UINib, reuseIdentifier: String) {
            self.container.registerNib(nib, forCellWithReuseIdentifier: reuseIdentifier)
        }
        
        public final func registerHeaderViewNib(nib: UINib, reuseIdentifier: String) {
            self.container.registerNib(nib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: reuseIdentifier)
        }
        
        public final func registerFooterViewNib(nib: UINib, reuseIdentifier: String) {
            self.container.registerNib(nib, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: reuseIdentifier)
        }
        
    }
    
    extension DataSource where T: UICollectionView {
        
        public final func dequeueReusableCell<ReusableCellType: Container>(for indexPath: NSIndexPath) -> ReusableCellType {
            let indexPath = self.parentDataSource == nil ? indexPath : self.parentDataSource!.globalIndexPath(for: self, localIndexPath: indexPath)
            
            return self.container.dequeueReusableCellWithReuseIdentifier(String(ReusableCellType.self), forIndexPath: indexPath) as! ReusableCellType
        }
        
        public final func dequeueReusableHeaderView<ReusableHeaderViewType: UICollectionReusableView>(for indexPath: NSIndexPath) -> ReusableHeaderViewType {
            let indexPath = self.parentDataSource == nil ? indexPath : self.parentDataSource!.globalIndexPath(for: self, localIndexPath: indexPath)
            
            return self.container.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: String(ReusableHeaderViewType.self), forIndexPath: indexPath) as! ReusableHeaderViewType
        }
        
        public final func dequeueReusableFooterView<ReusableFooterViewType: UICollectionReusableView>(for indexPath: NSIndexPath) -> ReusableFooterViewType {
            let indexPath = self.parentDataSource == nil ? indexPath : self.parentDataSource!.globalIndexPath(for: self, localIndexPath: indexPath)
            
            return self.container.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: String(ReusableFooterViewType.self), forIndexPath: indexPath) as! ReusableFooterViewType
        }
        
    }
    
    // MARK: -
    
    extension FetchRequestControllerDataSource where T: UICollectionView {
        
        public func bind() {
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
                    let newSectionIndex = self.globalSection(forLocalSection: newSectionIndex)
                    
                    insertedSectionIndexes.addIndex(newSectionIndex)
                }
                .didDeleteSection { sectionInfo, sectionIndex in
                    let sectionIndex = self.globalSection(forLocalSection: sectionIndex)
                    
                    deletedSectionIndexes.addIndex(sectionIndex)
                    deletedItemIndexPaths = deletedItemIndexPaths.filter { $0.section != sectionIndex }
                    updatedItemIndexPaths = updatedItemIndexPaths.filter { $0.section != sectionIndex }
                }
                .didUpdateSection { sectionInfo, sectionIndex in
                    let sectionIndex = self.globalSection(forLocalSection: sectionIndex)
                    
                    updatedSectionIndexes.addIndex(sectionIndex)
                }
                .didInsertEntity { entity, newIndexPath in
                    let newIndexPath = self.globalIndexPath(forLocalIndexPath: newIndexPath)
                    
                    if !insertedSectionIndexes.containsIndex(newIndexPath.section) {
                        insertedItemIndexPaths.append(newIndexPath)
                    }
                }
                .didDeleteEntity { entity, indexPath in
                    let indexPath = self.globalIndexPath(forLocalIndexPath: indexPath)
                    
                    if !deletedSectionIndexes.containsIndex(indexPath.section) {
                        deletedItemIndexPaths.append(indexPath)
                    }
                }
                .didUpdateEntity { entity, indexPath in
                    let indexPath = self.globalIndexPath(forLocalIndexPath: indexPath)
                    
                    if !deletedSectionIndexes.containsIndex(indexPath.section) && deletedItemIndexPaths.indexOf(indexPath) == nil && updatedItemIndexPaths.indexOf(indexPath) == nil {
                        updatedItemIndexPaths.append(indexPath)
                    }
                }
                .didMoveEntity { entity, indexPath, newIndexPath in
                    let indexPath = self.globalIndexPath(forLocalIndexPath: indexPath)
                    let newIndexPath = self.globalIndexPath(forLocalIndexPath: newIndexPath)
                    
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
                    let collectionView = self.container
                    
                    collectionView.performBatchUpdates(
                        {
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
                                collectionView.deleteItemsAtIndexPaths(deletedItemIndexPaths)
                            }
                            
                            if insertedItemIndexPaths.count > 0 {
                                collectionView.insertItemsAtIndexPaths(insertedItemIndexPaths)
                            }
                            
                            if updatedItemIndexPaths.count > 0 {
                                collectionView.reloadItemsAtIndexPaths(updatedItemIndexPaths)
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
