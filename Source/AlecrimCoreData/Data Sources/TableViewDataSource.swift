//
//  TableViewDataSource.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-05-21.
//  Copyright © 2016 Alecrim. All rights reserved.
//

#if os(iOS)

    import Foundation
    import UIKit

    public /* abstract */ class TableViewDataSource: AbstractDataSource {
        
        // MARK: -

        public final let tableView: UITableView
        
        // MARK: -

        public init(tableView: UITableView) {
            self.tableView = tableView
            super.init()
        }
        
        // MARK: -
        
        internal override func numberOfSections() -> Int {
            return self.numberOfSectionsInTableView(self.tableView)
        }
        
    }
    
    extension TableViewDataSource {
        
        public /* abstract */ func configureCell(cell: UITableViewCell, at indexPath: NSIndexPath) {
            fatalError()
        }
        
    }
    
    extension TableViewDataSource {
        
        public override final func globalSection(forLocalSection localSection: Int) -> Int {
            if let parentDataSource = self.parentDataSource as? ComposedTableViewDataSource {
                return parentDataSource.globalSection(for: self, localSection: localSection)
            }
            
            return localSection
        }
        
        public override final func globalIndexPath(forLocalIndexPath localIndexPath: NSIndexPath) -> NSIndexPath {
            if let parentDataSource = self.parentDataSource as? ComposedTableViewDataSource {
                return parentDataSource.globalIndexPath(for: self, localIndexPath: localIndexPath)
            }
            
            return localIndexPath
        }
        
        public override final func localSection(forGlobalSection globalSection: Int) -> Int {
            if let parentDataSource = self.parentDataSource as? ComposedTableViewDataSource {
                return parentDataSource.localSection(for: self, globalSection: globalSection)
            }
            
            return globalSection
        }
        
        public override final func localIndexPath(forGlobalIndexPath globalIndexPath: NSIndexPath) -> NSIndexPath {
            if let parentDataSource = self.parentDataSource as? ComposedTableViewDataSource {
                return parentDataSource.localIndexPath(for: self, globalIndexPath: globalIndexPath)
            }
            
            return globalIndexPath
        }

    }
    
    // MARK: -
    
    extension TableViewDataSource {
        
        //
        
        public final func registerCellClass<ReusableCellType: UITableViewCell>(cellClass: ReusableCellType.Type) {
            self.tableView.registerClass(cellClass, forCellReuseIdentifier: String(cellClass))
        }
        
        public final func registerHeaderViewClass<ReusableHeaderViewType: UITableViewHeaderFooterView>(headerViewClass: ReusableHeaderViewType.Type) {
            self.tableView.registerClass(headerViewClass, forHeaderFooterViewReuseIdentifier: String(headerViewClass))
        }
        
        public final func registerFooterViewClass<ReusableFooterViewType: UITableViewHeaderFooterView>(footerViewClass: ReusableFooterViewType.Type) {
            self.tableView.registerClass(footerViewClass, forHeaderFooterViewReuseIdentifier: String(footerViewClass))
        }
        
        //
        
        public final func registerCellNib<ReusableCellType: UITableViewCell>(with cellClass: ReusableCellType.Type, bundle: NSBundle? = nil) {
            self.registerCellNib(withName: String(cellClass), bundle: bundle)
        }
        
        public final func registerHeaderViewNib<ReusableHeaderViewType: UITableViewHeaderFooterView>(with headerViewClass: ReusableHeaderViewType.Type, bundle: NSBundle? = nil) {
            self.registerHeaderViewNib(withName: String(headerViewClass), bundle: bundle)
        }
        
        public final func registerFooterViewNib<ReusableFooterViewType: UITableViewHeaderFooterView>(with footerViewClass: ReusableFooterViewType.Type, bundle: NSBundle? = nil, reuseIdentifier: String) {
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
            self.tableView.registerNib(nib, forCellReuseIdentifier: reuseIdentifier)
        }
        
        public final func registerHeaderViewNib(nib: UINib, reuseIdentifier: String) {
            self.tableView.registerNib(nib, forHeaderFooterViewReuseIdentifier: reuseIdentifier)
        }
        
        public final func registerFooterViewNib(nib: UINib, reuseIdentifier: String) {
            self.tableView.registerNib(nib, forHeaderFooterViewReuseIdentifier: reuseIdentifier)
        }
        
    }
    
    extension TableViewDataSource {
        
        public final func dequeueReusableCell<ReusableCellType: UITableViewCell>(for indexPath: NSIndexPath) -> ReusableCellType {
            let indexPath = self.globalIndexPath(forLocalIndexPath: indexPath)
            
            return self.tableView.dequeueReusableCellWithIdentifier(String(ReusableCellType.self), forIndexPath: indexPath) as! ReusableCellType
        }
        
        public final func dequeueReusableHeaderView<ReusableHeaderViewType: UITableViewHeaderFooterView>() -> ReusableHeaderViewType {
            return self.tableView.dequeueReusableHeaderFooterViewWithIdentifier(String(ReusableHeaderViewType.self)) as! ReusableHeaderViewType
        }
        
        public final func dequeueReusableFooterView<ReusableFooterViewType: UITableViewHeaderFooterView>() -> ReusableFooterViewType {
            return self.tableView.dequeueReusableHeaderFooterViewWithIdentifier(String(ReusableFooterViewType.self)) as! ReusableFooterViewType
        }
        
    }
    
    extension TableViewDataSource {
        
        public final func beginUpdates() {
            self.tableView.beginUpdates()
        }
        
        public final func insertSections(sections: NSIndexSet, with animation: UITableViewRowAnimation) {
            self.parentDataSource?.updateMappings()
            
            let mis = NSMutableIndexSet()
            
            for section in sections {
                mis.addIndex(self.globalSection(forLocalSection: section))
            }
            
            self.tableView.insertSections(mis, withRowAnimation: animation)
        }
        
        public final func deleteSections(sections: NSIndexSet, with animation: UITableViewRowAnimation) {
            self.parentDataSource?.updateMappings()
            
            let mis = NSMutableIndexSet()
            
            for section in sections {
                mis.addIndex(self.globalSection(forLocalSection: section))
            }
            
            self.tableView.deleteSections(mis, withRowAnimation: animation)
        }
        
        public final func reloadSections(sections: NSIndexSet, with animation: UITableViewRowAnimation) {
            self.parentDataSource?.updateMappings()
            
            let mis = NSMutableIndexSet()
            
            for section in sections {
                mis.addIndex(self.globalSection(forLocalSection: section))
            }
            
            self.tableView.reloadSections(mis, withRowAnimation: animation)
        }
        
        public final func moveSection(section: Int, toSection newSection: Int) {
            self.parentDataSource?.updateMappings()
            
            let section = self.globalSection(forLocalSection: section)
            let newSection = self.globalSection(forLocalSection: newSection)
            
            self.tableView.moveSection(section, toSection: newSection)
        }
        
        public final func insertRows(at indexPaths: [NSIndexPath], with animation: UITableViewRowAnimation) {
            let indexPaths = indexPaths.map { self.globalIndexPath(forLocalIndexPath: $0) }
            self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
        }
        
        public final func deleteRows(at indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
            let indexPaths = indexPaths.map { self.globalIndexPath(forLocalIndexPath: $0) }
            self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
        }
        
        public final func reloadRows(at indexPaths: [NSIndexPath], withRowAnimation animation: UITableViewRowAnimation) {
            let indexPaths = indexPaths.map { self.globalIndexPath(forLocalIndexPath: $0) }
            self.tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: animation)
        }
        
        public final func moveRow(at indexPath: NSIndexPath, to newIndexPath: NSIndexPath) {
            let indexPath = self.globalIndexPath(forLocalIndexPath: indexPath)
            let newIndexPath = self.globalIndexPath(forLocalIndexPath: newIndexPath)
            
            self.tableView.moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)
        }
        
        public final func endUpdates() {
            self.tableView.endUpdates()
        }
        
        
    }


    
    // MARK: -
    
    extension TableViewDataSource: UITableViewDataSource {
        
        public /* abstract */ func numberOfSectionsInTableView(tableView: UITableView) -> Int {
            return 0
        }
        
        public /* abstract */ func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return 0
        }
        
        public /* abstract */ func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
            fatalError()
        }
        
    }
    
    extension TableViewDataSource: UITableViewDelegate {
        
        public func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            return self.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
        
        public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            return 0
        }
        
        public func tableView(tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
            return self.tableView(tableView, heightForHeaderInSection: section)
        }
        
        public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return 0
        }
        
        public func tableView(tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
            return self.tableView(tableView, heightForFooterInSection: section)
        }
        
        public func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
            return 0
        }
        
    }
    

#endif
