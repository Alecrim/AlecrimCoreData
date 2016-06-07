//
//  CollectionViewDataSource.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-05-21.
//  Copyright © 2016 Alecrim. All rights reserved.
//

#if os(iOS)

    import Foundation
    import UIKit

    public /* abstract */ class CollectionViewDataSource: AbstractDataSource {
        
        // MARK: -

        public final let collectionView: UICollectionView
        
        // MARK: -

        public init(collectionView: UICollectionView) {
            self.collectionView = collectionView
            super.init()
        }
        
        // MARK: -
        
        internal override func numberOfSections() -> Int {
            return self.numberOfSectionsInCollectionView(self.collectionView)
        }
        
    }
    
    extension CollectionViewDataSource {
        
        public /* abstract */ func configureCell(cell: UICollectionViewCell, at indexPath: NSIndexPath) {
            fatalError()
        }
        
    }
    
    extension CollectionViewDataSource {
        
        public override final func globalSection(forLocalSection localSection: Int) -> Int {
            if let parentDataSource = self.parentDataSource as? ComposedCollectionViewDataSource {
                return parentDataSource.globalSection(for: self, localSection: localSection)
            }
            
            return localSection
        }
        
        public override final func globalIndexPath(forLocalIndexPath localIndexPath: NSIndexPath) -> NSIndexPath {
            if let parentDataSource = self.parentDataSource as? ComposedCollectionViewDataSource {
                return parentDataSource.globalIndexPath(for: self, localIndexPath: localIndexPath)
            }
            
            return localIndexPath
        }
        
        public override final func localSection(forGlobalSection globalSection: Int) -> Int {
            if let parentDataSource = self.parentDataSource as? ComposedCollectionViewDataSource {
                return parentDataSource.localSection(for: self, globalSection: globalSection)
            }
            
            return globalSection
        }
        
        public override final func localIndexPath(forGlobalIndexPath globalIndexPath: NSIndexPath) -> NSIndexPath {
            if let parentDataSource = self.parentDataSource as? ComposedCollectionViewDataSource {
                return parentDataSource.localIndexPath(for: self, globalIndexPath: globalIndexPath)
            }
            
            return globalIndexPath
        }

    }
    
    // MARK: -
    
    extension CollectionViewDataSource {
        
        //
        
        public final func registerCellClass<ReusableCellType: UICollectionViewCell>(cellClass: ReusableCellType.Type) {
            self.collectionView.registerClass(cellClass, forCellWithReuseIdentifier: String(cellClass))
        }
        
        public final func registerHeaderViewClass<ReusableHeaderViewType: UICollectionReusableView>(headerViewClass: ReusableHeaderViewType.Type) {
            self.collectionView.registerClass(headerViewClass, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: String(headerViewClass))
        }
        
        public final func registerFooterViewClass<ReusableFooterViewType: UICollectionReusableView>(footerViewClass: ReusableFooterViewType.Type) {
            self.collectionView.registerClass(footerViewClass, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: String(footerViewClass))
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
            self.collectionView.registerNib(nib, forCellWithReuseIdentifier: reuseIdentifier)
        }
        
        public final func registerHeaderViewNib(nib: UINib, reuseIdentifier: String) {
            self.collectionView.registerNib(nib, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: reuseIdentifier)
        }
        
        public final func registerFooterViewNib(nib: UINib, reuseIdentifier: String) {
            self.collectionView.registerNib(nib, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: reuseIdentifier)
        }
        
    }
    
    extension CollectionViewDataSource {
        
        public final func dequeueReusableCell<ReusableCellType: UICollectionViewCell>(for indexPath: NSIndexPath) -> ReusableCellType {
            let indexPath = self.globalIndexPath(forLocalIndexPath: indexPath)
            
            return self.collectionView.dequeueReusableCellWithReuseIdentifier(String(ReusableCellType.self), forIndexPath: indexPath) as! ReusableCellType
        }
        
        public final func dequeueReusableHeaderView<ReusableHeaderViewType: UICollectionReusableView>(for indexPath: NSIndexPath) -> ReusableHeaderViewType {
            let indexPath = self.globalIndexPath(forLocalIndexPath: indexPath)
            
            return self.collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionHeader, withReuseIdentifier: String(ReusableHeaderViewType.self), forIndexPath: indexPath) as! ReusableHeaderViewType
        }
        
        public final func dequeueReusableFooterView<ReusableFooterViewType: UICollectionReusableView>(for indexPath: NSIndexPath) -> ReusableFooterViewType {
            let indexPath = self.globalIndexPath(forLocalIndexPath: indexPath)
            
            return self.collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: String(ReusableFooterViewType.self), forIndexPath: indexPath) as! ReusableFooterViewType
        }
        
    }
    
    extension CollectionViewDataSource {
        
        public final func insertSections(sections: NSIndexSet) {
            let mis = NSMutableIndexSet()
            
            for section in sections {
                mis.addIndex(self.globalSection(forLocalSection: section))
            }
            
            self.collectionView.insertSections(mis)
        }
        
        public final func deleteSections(sections: NSIndexSet) {
            let mis = NSMutableIndexSet()
            
            for section in sections {
                mis.addIndex(self.globalSection(forLocalSection: section))
            }
            
            self.collectionView.deleteSections(mis)
        }
        
        public final func reloadSections(sections: NSIndexSet) {
            let mis = NSMutableIndexSet()
            
            for section in sections {
                mis.addIndex(self.globalSection(forLocalSection: section))
            }
            
            self.collectionView.reloadSections(mis)
        }
        
        public final func moveSection(section: Int, toSection newSection: Int) {
            let section = self.globalSection(forLocalSection: section)
            let newSection = self.globalSection(forLocalSection: newSection)
            
            self.collectionView.moveSection(section, toSection: newSection)
        }
        
        public final func insertItems(at indexPaths: [NSIndexPath]) {
            let indexPaths = indexPaths.map { self.globalIndexPath(forLocalIndexPath: $0) }
            self.collectionView.insertItemsAtIndexPaths(indexPaths)
        }
        
        public final func deleteItems(at indexPaths: [NSIndexPath]) {
            let indexPaths = indexPaths.map { self.globalIndexPath(forLocalIndexPath: $0) }
            self.collectionView.deleteItemsAtIndexPaths(indexPaths)
        }
        
        public final func reloadItems(at indexPaths: [NSIndexPath]) {
            let indexPaths = indexPaths.map { self.globalIndexPath(forLocalIndexPath: $0) }
            self.collectionView.reloadItemsAtIndexPaths(indexPaths)
        }
        
        public final func moveItem(at indexPath: NSIndexPath, to newIndexPath: NSIndexPath) {
            let indexPath = self.globalIndexPath(forLocalIndexPath: indexPath)
            let newIndexPath = self.globalIndexPath(forLocalIndexPath: newIndexPath)
            
            self.collectionView.moveItemAtIndexPath(indexPath, toIndexPath: newIndexPath)
        }
        
        public final func performBatchUpdates(updates: (() -> Void)?, completion: ((Bool) -> Void)? = nil) {
            if let updates = updates {
                let effectiveUpdates: () -> Void = {
                    self.parentDataSource?.updateMappings()
                    updates()
                }
                
                self.collectionView.performBatchUpdates(effectiveUpdates, completion: completion)
            }
            else {
                self.collectionView.performBatchUpdates(updates, completion: completion)
            }
        }
        
    }
    
    // MARK: -
    
    extension CollectionViewDataSource: UICollectionViewDataSource {
        
        public /* abstract */ func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
            return 0
        }
        
        public /* abstract */ func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return 0
        }

        public /* abstract */ func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            fatalError()
        }
        
    }
    
    extension CollectionViewDataSource: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
        
    }
    

#endif
