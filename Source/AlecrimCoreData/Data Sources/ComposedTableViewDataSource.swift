//
//  ComposedTableViewDataSource.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-05-22.
//  Copyright © 2016 Alecrim. All rights reserved.
//

#if os(iOS)

import Foundation

public /* abstract */ class ComposedTableViewDataSource: TableViewDataSource {
    
    // MARK: -
    
    private var mappings = [DataSourceMapping<TableViewDataSource>]()
    private let dataSourceToMappings = NSMapTable(keyOptions: .ObjectPointerPersonality, valueOptions: .StrongMemory, capacity: 1)
    private var globalSectionToMappings = [Int : DataSourceMapping<TableViewDataSource>]()
    
    //
    
    private var _numberOfSections = 0
    
    // MARK: -
    
    public let dataSources: [AbstractDataSource]
    
    // MARK: -
    
    public init(for tableView: UITableView, dataSources: [TableViewDataSource]) {
        self.dataSources = dataSources
        super.init(tableView: tableView)
        
        self.dataSources.forEach { dataSource in
            let mappingForDataSource = DataSourceMapping(dataSource: dataSource as! TableViewDataSource)
            self.mappings.append(mappingForDataSource)
            self.dataSourceToMappings.setObject(mappingForDataSource, forKey: dataSource)
            
            dataSource.parentDataSource = self
        }
        
        self.updateMappings()
    }
    
}

extension ComposedTableViewDataSource {
    
    // MARK: -
    
    public override final func configureCell(cell: UITableViewCell, at indexPath: NSIndexPath) {
        //
        let mapping = self.mapping(forGlobalSection: indexPath.section)
        let dataSource = mapping.dataSource
        let localIndexPath = mapping.localIndexPath(forGlobalIndexPath: indexPath)
        
        //
        dataSource.configureCell(cell, at: localIndexPath)
    }
    
    public override final func dataSource(at indexPath: NSIndexPath) -> AbstractDataSource {
        let mapping = self.mapping(forGlobalSection: indexPath.section)
        let dataSource = mapping.dataSource
        
        return dataSource
    }
    
}

extension ComposedTableViewDataSource {
    
    internal func globalSection(for dataSource: AbstractDataSource, localSection: Int) -> Int {
        return self.mapping(for: dataSource).globalSection(forLocalSection: localSection)
    }
    
    internal func globalIndexPath(for dataSource: AbstractDataSource, localIndexPath: NSIndexPath) -> NSIndexPath {
        return self.mapping(for: dataSource).globalIndexPath(forLocalIndexPath: localIndexPath)
    }
    
    internal func localSection(for dataSource: AbstractDataSource, globalSection: Int) -> Int {
        return self.mapping(for: dataSource).localSection(forGlobalSection: globalSection)
    }
    
    internal func localIndexPath(for dataSource: AbstractDataSource, globalIndexPath: NSIndexPath) -> NSIndexPath {
        return self.mapping(for: dataSource).localIndexPath(forGlobalIndexPath: globalIndexPath)
    }
    
}

extension ComposedTableViewDataSource {
    
    private func mapping(forGlobalSection section: Int) -> DataSourceMapping<TableViewDataSource> {
        return self.globalSectionToMappings[section]!
    }
    
    private func mapping(for dataSource: AbstractDataSource) -> DataSourceMapping<TableViewDataSource> {
        return self.dataSourceToMappings.objectForKey(dataSource) as! DataSourceMapping<TableViewDataSource>
    }
    
}

extension ComposedTableViewDataSource {
    
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

extension ComposedTableViewDataSource {
    
    // MARK: -
    
    public override final func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        self.updateMappings()
        return self._numberOfSections
    }
    
    public override final func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        return dataSource.tableView(self.tableView, numberOfRowsInSection: localSection)
    }
    
    public override final func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //
        let mapping = self.mapping(forGlobalSection: indexPath.section)
        let dataSource = mapping.dataSource
        let localIndexPath = mapping.localIndexPath(forGlobalIndexPath: indexPath)
        
        //
        return dataSource.tableView(self.tableView, cellForRowAtIndexPath: localIndexPath)
    }
    
    // MARK: -
    
    public func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let ds = self.dataSource(atSectionIndex: section)
        return (ds as! UITableViewDataSource).tableView?(tableView, titleForHeaderInSection: ds.localSection(forGlobalSection: section))
    }
    
    public final func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let ds = self.dataSource(atSectionIndex: section)
        return (ds as! UITableViewDataSource).tableView?(tableView, titleForFooterInSection: ds.localSection(forGlobalSection: section))
    }
    
    public final func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UITableViewDataSource).tableView?(tableView, canEditRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? true
    }
    
    public final func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UITableViewDataSource).tableView?(tableView, canMoveRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? ((ds as! UITableViewDataSource).tableView(_:moveRowAtIndexPath:toIndexPath:) != nil)
    }
    
//    public final func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]?
//    public final func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int
    
    public final func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UITableViewDataSource).tableView?(tableView, commitEditingStyle: editingStyle, forRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public final func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let ds = self.dataSource(at: sourceIndexPath)
        (ds as! UITableViewDataSource).tableView?(tableView, moveRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: sourceIndexPath), toIndexPath: ds.localIndexPath(forGlobalIndexPath: destinationIndexPath))
    }
    
}

extension ComposedTableViewDataSource {
    
    public final func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UITableViewDelegate).tableView?(tableView, willDisplayCell: cell, forRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public final func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let ds = self.dataSource(atSectionIndex: section)
        (ds as! UITableViewDelegate).tableView?(tableView, willDisplayHeaderView: view, forSection: ds.localSection(forGlobalSection: section))
    }
    
    public final func tableView(tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        let ds = self.dataSource(atSectionIndex: section)
        (ds as! UITableViewDelegate).tableView?(tableView, willDisplayFooterView: view, forSection: ds.localSection(forGlobalSection: section))
    }
    
    // FIXME:
//    public final func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
//        let ds = self.dataSource(at: indexPath)
//        (ds as! UITableViewDelegate).tableView?(tableView, didEndDisplayingCell: cell, forRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
//    }
    
    // FIXME:
//    public final func tableView(tableView: UITableView, didEndDisplayingHeaderView view: UIView, forSection section: Int) {
//        let ds = self.dataSource(atSectionIndex: section)
//        (ds as! UITableViewDelegate).tableView?(tableView, didEndDisplayingHeaderView: view, forSection: ds.localSection(forGlobalSection: section))
//    }
    
    // FIXME:
//    public final func tableView(tableView: UITableView, didEndDisplayingFooterView view: UIView, forSection section: Int) {
//        let ds = self.dataSource(atSectionIndex: section)
//        (ds as! UITableViewDelegate).tableView?(tableView, didEndDisplayingFooterView: view, forSection: ds.localSection(forGlobalSection: section))
//    }
    
    public final override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UITableViewDelegate).tableView?(tableView, heightForRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? tableView.rowHeight
    }
    
    public final override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let ds = self.dataSource(atSectionIndex: section)
        return (ds as! UITableViewDelegate).tableView?(tableView, heightForHeaderInSection: ds.localSection(forGlobalSection: section)) ?? tableView.sectionHeaderHeight
    }
    
    public final override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let ds = self.dataSource(atSectionIndex: section)
        return (ds as! UITableViewDelegate).tableView?(tableView, heightForFooterInSection: ds.localSection(forGlobalSection: section)) ?? tableView.sectionFooterHeight
    }
    
    public final override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UITableViewDelegate).tableView?(tableView, estimatedHeightForRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? tableView.estimatedRowHeight
    }
    
    public final override func tableView(tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        let ds = self.dataSource(atSectionIndex: section)
        return (ds as! UITableViewDelegate).tableView?(tableView, estimatedHeightForHeaderInSection: ds.localSection(forGlobalSection: section)) ?? tableView.estimatedSectionHeaderHeight
    }
    
    public final override func tableView(tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        let ds = self.dataSource(atSectionIndex: section)
        return (ds as! UITableViewDelegate).tableView?(tableView, estimatedHeightForFooterInSection: ds.localSection(forGlobalSection: section)) ?? tableView.estimatedSectionFooterHeight
    }
    
    public final func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let ds = self.dataSource(atSectionIndex: section)
        return (ds as! UITableViewDelegate).tableView?(tableView, viewForHeaderInSection: ds.localSection(forGlobalSection: section))
    }
    
    public final func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let ds = self.dataSource(atSectionIndex: section)
        return (ds as! UITableViewDelegate).tableView?(tableView, viewForFooterInSection: ds.localSection(forGlobalSection: section))
    }
    
    public final func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UITableViewDelegate).tableView?(tableView, accessoryButtonTappedForRowWithIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public final func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UITableViewDelegate).tableView?(tableView, shouldHighlightRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? true
    }
    
    public final func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UITableViewDelegate).tableView?(tableView, didHighlightRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public final func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UITableViewDelegate).tableView?(tableView, didUnhighlightRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public final func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        let ds = self.dataSource(at: indexPath)
        
        if let willSelectRow = (ds as! UITableViewDelegate).tableView(_:willSelectRowAtIndexPath:) {
            if let returningIndexPath = willSelectRow(tableView, willSelectRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) {
                return ds.globalIndexPath(forLocalIndexPath: returningIndexPath)
            }
            else {
                return nil
            }
        }
        else {
            return indexPath
        }
    }
    
    public final func tableView(tableView: UITableView, willDeselectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        let ds = self.dataSource(at: indexPath)
        
        if let willDeselectRow = (ds as! UITableViewDelegate).tableView(_:willDeselectRowAtIndexPath:) {
            if let returningIndexPath = willDeselectRow(tableView, willDeselectRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) {
                return ds.globalIndexPath(forLocalIndexPath: returningIndexPath)
            }
            else {
                return nil
            }
        }
        else {
            return indexPath
        }
    }
    
    public final func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UITableViewDelegate).tableView?(tableView, didSelectRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public final func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UITableViewDelegate).tableView?(tableView, didDeselectRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public final func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UITableViewDelegate).tableView?(tableView, editingStyleForRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? (tableView.editing ? .Delete : .None)
    }
    
    public final func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UITableViewDelegate).tableView?(tableView, titleForDeleteConfirmationButtonForRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public final func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UITableViewDelegate).tableView?(tableView, editActionsForRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public final func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UITableViewDelegate).tableView?(tableView, shouldIndentWhileEditingRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? true
    }
    
    public final func tableView(tableView: UITableView, willBeginEditingRowAtIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UITableViewDelegate).tableView?(tableView, willBeginEditingRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public final func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UITableViewDelegate).tableView?(tableView, didEndEditingRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath))
    }
    
    public final func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        let ds = self.dataSource(at: sourceIndexPath)

        if let targetIndexPathForMove = (ds as! UITableViewDelegate).tableView(_:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:) {
            let returningIndexPath = targetIndexPathForMove(tableView, targetIndexPathForMoveFromRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: sourceIndexPath), toProposedIndexPath: ds.localIndexPath(forGlobalIndexPath: proposedDestinationIndexPath))
            return ds.globalIndexPath(forLocalIndexPath: returningIndexPath)
        }
        else {
            return proposedDestinationIndexPath
        }
    }
    
    public final func tableView(tableView: UITableView, indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int {
        let ds = self.dataSource(at: indexPath)
        
        if let indentationLevel = (ds as! UITableViewDelegate).tableView?(tableView, indentationLevelForRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) {
            return indentationLevel
        }
        else {
            // TODO: verify default behavior
            //                if let cell = tableView.cellForRowAtIndexPath(indexPath) {
            //                    return cell.indentationLevel
            //                }
            //                else {
            return 0
            //                }
        }
    }
    
    public final func tableView(tableView: UITableView, shouldShowMenuForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UITableViewDelegate).tableView?(tableView, shouldShowMenuForRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? false
    }
    
    public final func tableView(tableView: UITableView, canPerformAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UITableViewDelegate).tableView?(tableView, canPerformAction: action, forRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath), withSender: sender) ?? false
    }
    
    public final func tableView(tableView: UITableView, performAction action: Selector, forRowAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
        let ds = self.dataSource(at: indexPath)
        (ds as! UITableViewDelegate).tableView?(tableView, performAction: action, forRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath), withSender: sender)
    }
    
    @available(iOSApplicationExtension 9.0, *)
    public final func tableView(tableView: UITableView, canFocusRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        let ds = self.dataSource(at: indexPath)
        return (ds as! UITableViewDelegate).tableView?(tableView, canFocusRowAtIndexPath: ds.localIndexPath(forGlobalIndexPath: indexPath)) ?? true
    }
    
//    public final func tableView(tableView: UITableView, shouldUpdateFocusInContext context: UITableViewFocusUpdateContext) -> Bool
//    public final func tableView(tableView: UITableView, didUpdateFocusInContext context: UITableViewFocusUpdateContext, withAnimationCoordinator coordinator: UIFocusAnimationCoordinator) {
//    public final func indexPathForPreferredFocusedViewInTableView(tableView: UITableView) -> NSIndexPath? {
    
}

#endif
