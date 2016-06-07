//
//  ComposedCollectionViewDataSource.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-05-22.
//  Copyright © 2016 Alecrim. All rights reserved.
//

#if os(iOS)

import Foundation

public /* abstract */ class ComposedCollectionViewDataSource: CollectionViewDataSource {
    
    // MARK: -
    
    private var mappings = [DataSourceMapping<CollectionViewDataSource>]()
    private let dataSourceToMappings = NSMapTable(keyOptions: .ObjectPointerPersonality, valueOptions: .StrongMemory, capacity: 1)
    private var globalSectionToMappings = [Int : DataSourceMapping<CollectionViewDataSource>]()
    
    //
    
    private var _numberOfSections = 0
    
    // MARK: -
    
    public let dataSources: [DataSource]
    
    // MARK: -
    
    public init(for collectionView: UICollectionView, dataSources: [CollectionViewDataSource]) {
        self.dataSources = dataSources
        super.init(collectionView: collectionView)
        
        self.dataSources.forEach { dataSource in
            let mappingForDataSource = DataSourceMapping(dataSource: dataSource as! CollectionViewDataSource)
            self.mappings.append(mappingForDataSource)
            self.dataSourceToMappings.setObject(mappingForDataSource, forKey: dataSource)
            
            dataSource.parentDataSource = self
        }
        
        self.updateMappings()
    }
    
}

extension ComposedCollectionViewDataSource {
    
    // MARK: -
    
    public override final func configureCell(cell: UICollectionViewCell, at indexPath: NSIndexPath) {
        //
        let mapping = self.mapping(forGlobalSection: indexPath.section)
        let dataSource = mapping.dataSource
        let localIndexPath = mapping.localIndexPath(forGlobalIndexPath: indexPath)
        
        //
        dataSource.configureCell(cell, at: localIndexPath)
    }
    
    public override final func dataSource(at indexPath: NSIndexPath) -> DataSource {
        let mapping = self.mapping(forGlobalSection: indexPath.section)
        let dataSource = mapping.dataSource
        
        return dataSource
    }
    
}

extension ComposedCollectionViewDataSource {
    
    internal func globalSection(for dataSource: DataSource, localSection: Int) -> Int {
        return self.mapping(for: dataSource).globalSection(forLocalSection: localSection)
    }
    
    internal func globalIndexPath(for dataSource: DataSource, localIndexPath: NSIndexPath) -> NSIndexPath {
        return self.mapping(for: dataSource).globalIndexPath(forLocalIndexPath: localIndexPath)
    }
    
    internal func localSection(for dataSource: DataSource, globalSection: Int) -> Int {
        return self.mapping(for: dataSource).localSection(forGlobalSection: globalSection)
    }
    
    internal func localIndexPath(for dataSource: DataSource, globalIndexPath: NSIndexPath) -> NSIndexPath {
        return self.mapping(for: dataSource).localIndexPath(forGlobalIndexPath: globalIndexPath)
    }
    
}

extension ComposedCollectionViewDataSource {
    
    private func mapping(forGlobalSection section: Int) -> DataSourceMapping<CollectionViewDataSource> {
        return self.globalSectionToMappings[section]!
    }
    
    private func mapping(for dataSource: DataSource) -> DataSourceMapping<CollectionViewDataSource> {
        return self.dataSourceToMappings.objectForKey(dataSource) as! DataSourceMapping<CollectionViewDataSource>
    }
    
}

extension ComposedCollectionViewDataSource {
    
    internal override final func updateMappings() {
        self._numberOfSections = 0
        self.globalSectionToMappings.removeAll()
        
        for mapping in self.mappings {
            mapping.updateMappingStarting(atGlobalSection: self._numberOfSections) { sectionIndex in
                self.globalSectionToMappings[sectionIndex] = mapping
            }
            
            self._numberOfSections += mapping.numberOfSections
        }
    }
    
}

extension ComposedCollectionViewDataSource {
    
    // MARK: -
    
    public override final func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        self.updateMappings()
        return self._numberOfSections
    }
    
    public override final func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //
        self.updateMappings()
        
        //
        let mapping = self.mapping(forGlobalSection: section)
        let dataSource = mapping.dataSource
        
        //
        let localSection = mapping.localSection(forGlobalSection: section)
        let numberOfSections = dataSource.numberOfSections()
        
        assert(localSection < numberOfSections, "local section is out of bounds for composed data source")
        
        //
        return dataSource.collectionView(self.collectionView, numberOfItemsInSection: localSection)
    }
    
    public override final func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        //
        let mapping = self.mapping(forGlobalSection: indexPath.section)
        let dataSource = mapping.dataSource
        let localIndexPath = mapping.localIndexPath(forGlobalIndexPath: indexPath)
        
        //
        return dataSource.collectionView(self.collectionView, cellForItemAtIndexPath: localIndexPath)
    }
    
    // MARK: -
    
    public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UICollectionViewDataSource).collectionView?(collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? UICollectionReusableView(frame: CGRect.zero)
    }
    
    @available(iOSApplicationExtension 9.0, *)
    public func collectionView(collectionView: UICollectionView, canMoveItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UICollectionViewDataSource).collectionView?(collectionView, canMoveItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? false
    }
    
    @available(iOSApplicationExtension 9.0, *)
    public func collectionView(collectionView: UICollectionView, moveItemAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let ds = self.dataSource(at: sourceIndexPath)
        (ds as! UICollectionViewDataSource).collectionView?(collectionView, moveItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: sourceIndexPath), toIndexPath: ds.localIndexPath(forGlobalIndexPath: destinationIndexPath))
    }
}

extension ComposedTableViewDataSource {
    
    public func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UICollectionViewDelegate).collectionView?(collectionView, shouldHighlightItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? true
    }
    
    public func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UICollectionViewDelegate).collectionView?(collectionView, didHighlightItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public func collectionView(collectionView: UICollectionView, didUnhighlightItemAtIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UICollectionViewDelegate).collectionView?(collectionView, didUnhighlightItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UICollectionViewDelegate).collectionView?(collectionView, shouldSelectItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? true
    }
    
    public func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UICollectionViewDelegate).collectionView?(collectionView, shouldDeselectItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? true
    }
    
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UICollectionViewDelegate).collectionView?(collectionView, didSelectItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UICollectionViewDelegate).collectionView?(collectionView, didDeselectItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UICollectionViewDelegate).collectionView?(collectionView, willDisplayCell: cell, forItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public func collectionView(collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, atIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UICollectionViewDelegate).collectionView?(collectionView, willDisplaySupplementaryView: view, forElementKind: elementKind, atIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    // FIXME:
//    public func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
//        let ds = self.dataSource(at: indexPath)
//        (ds as! UICollectionViewDelegate).collectionView?(collectionView, didEndDisplayingCell: cell, forItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
//    }
    
    // FIXME:
//    public func collectionView(collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, atIndexPath indexPath: NSIndexPath) {
//        let ds = self.dataSource(at: indexPath)
//        (ds as! UICollectionViewDelegate).collectionView?(collectionView, didEndDisplayingSupplementaryView: view, forElementOfKind: elementKind, atIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
//    }
    
    public func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UICollectionViewDelegate).collectionView?(collectionView, shouldShowMenuForItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? false
    }
    
    public func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UICollectionViewDelegate).collectionView?(collectionView, canPerformAction: action, forItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath), withSender: sender) ?? false
    }
    
    public func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UICollectionViewDelegate).collectionView?(collectionView, performAction: action, forItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath), withSender: sender)
    }
    
    // public func collectionView(collectionView: UICollectionView, transitionLayoutForOldLayout fromLayout: UICollectionViewLayout, newLayout toLayout: UICollectionViewLayout) -> UICollectionViewTransitionLayout
    
    @available(iOSApplicationExtension 9.0, *)
    public func collectionView(collectionView: UICollectionView, canFocusItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UICollectionViewDelegate).collectionView?(collectionView, canFocusItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? collectionView.allowsSelection
    }
    
    // public func collectionView(collectionView: UICollectionView, shouldUpdateFocusInContext context: UICollectionViewFocusUpdateContext) -> Bool
    // public func collectionView(collectionView: UICollectionView, didUpdateFocusInContext context: UICollectionViewFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator)
    // public func indexPathForPreferredFocusedViewInCollectionView(collectionView: UICollectionView) -> NSIndexPath?
    
    @available(iOSApplicationExtension 9.0, *)
    public func collectionView(collectionView: UICollectionView, targetIndexPathForMoveFromItemAtIndexPath originalIndexPath: NSIndexPath, toProposedIndexPath proposedIndexPath: NSIndexPath) -> NSIndexPath {
        let ds = self.dataSource(at: originalIndexPath)

        if let targetIndexPathForMoveFromItem = (ds as! UICollectionViewDelegate).collectionView(_:targetIndexPathForMoveFromItemAtIndexPath:toProposedIndexPath:) {
            let returningIndexPath = targetIndexPathForMoveFromItem(collectionView, targetIndexPathForMoveFromItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: originalIndexPath), toProposedIndexPath: ds.localIndexPath(forGlobalIndexPath: proposedIndexPath)) ?? ds.localIndexPath(forGlobalIndexPath: proposedIndexPath)
            return ds.globalIndexPath(forLocalIndexPath: returningIndexPath)
        }
        else {
            return proposedIndexPath
        }
    }
    
    // public func collectionView(collectionView: UICollectionView, targetContentOffsetForProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint
    
}
    
    extension ComposedTableViewDataSource {
        
        public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            let ds = self.dataSource(at: indexPath)
            return (ds as! UICollectionViewDelegateFlowLayout).collectionView?(collectionView, layout: collectionViewLayout, sizeForItemAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? (collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        }
        
        public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            let ds = self.dataSource(atSectionIndex: section)
            return (ds as! UICollectionViewDelegateFlowLayout).collectionView?(collectionView, layout: collectionViewLayout, insetForSectionAtIndex: ds.localSection(forGlobalSection: section)) ?? (collectionViewLayout as! UICollectionViewFlowLayout).sectionInset
        }
        
        public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
            let ds = self.dataSource(atSectionIndex: section)
            return (ds as! UICollectionViewDelegateFlowLayout).collectionView?(collectionView, layout: collectionViewLayout, minimumLineSpacingForSectionAtIndex: ds.localSection(forGlobalSection: section)) ?? (collectionViewLayout as! UICollectionViewFlowLayout).minimumLineSpacing
        }
        
        public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
            let ds = self.dataSource(atSectionIndex: section)
            return (ds as! UICollectionViewDelegateFlowLayout).collectionView?(collectionView, layout: collectionViewLayout, minimumInteritemSpacingForSectionAtIndex: ds.localSection(forGlobalSection: section)) ?? (collectionViewLayout as! UICollectionViewFlowLayout).minimumInteritemSpacing
        }
        
        public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
            let ds = self.dataSource(atSectionIndex: section)
            return (ds as! UICollectionViewDelegateFlowLayout).collectionView?(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: ds.localSection(forGlobalSection: section)) ?? (collectionViewLayout as! UICollectionViewFlowLayout).headerReferenceSize
        }
        
        public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
            let ds = self.dataSource(atSectionIndex: section)
            return (ds as! UICollectionViewDelegateFlowLayout).collectionView?(collectionView, layout: collectionViewLayout, referenceSizeForFooterInSection: ds.localSection(forGlobalSection: section)) ?? (collectionViewLayout as! UICollectionViewFlowLayout).footerReferenceSize
        }
        
    }


#endif
