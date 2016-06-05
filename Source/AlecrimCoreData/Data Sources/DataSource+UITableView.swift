//
//  DataSource+UITableView.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-06-02.
//  Copyright © 2016 Alecrim. All rights reserved.
//

#if os(iOS)
    
    import Foundation
    import UIKit
    
    extension UITableView: Container {
    }
    
    extension UITableViewCell: ContainerCell {
    }
    
    extension DataSource where T: UITableView {
        
        //
        
        public final func registerCellClass<ReusableCellType: UITableViewCell>(cellClass: ReusableCellType.Type) {
            self.container.registerClass(cellClass, forCellReuseIdentifier: String(cellClass))
        }
        
        public final func registerHeaderViewClass<ReusableHeaderViewType: UITableViewHeaderFooterView>(headerViewClass: ReusableHeaderViewType.Type) {
            self.container.registerClass(headerViewClass, forHeaderFooterViewReuseIdentifier: String(headerViewClass))
        }
        
        public final func registerFooterViewClass<ReusableFooterViewType: UITableViewHeaderFooterView>(footerViewClass: ReusableFooterViewType.Type) {
            self.container.registerClass(footerViewClass, forHeaderFooterViewReuseIdentifier: String(footerViewClass))
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
            self.container.registerNib(nib, forCellReuseIdentifier: reuseIdentifier)
        }
        
        public final func registerHeaderViewNib(nib: UINib, reuseIdentifier: String) {
            self.container.registerNib(nib, forHeaderFooterViewReuseIdentifier: reuseIdentifier)
        }
        
        public final func registerFooterViewNib(nib: UINib, reuseIdentifier: String) {
            self.container.registerNib(nib, forHeaderFooterViewReuseIdentifier: reuseIdentifier)
        }
        
    }
    
    extension DataSource where T: UITableView {
        
        public final func dequeueReusableCell<ReusableCellType: UITableViewCell>(for indexPath: NSIndexPath) -> ReusableCellType {
            let indexPath = self.parentDataSource == nil ? indexPath : self.parentDataSource!.globalIndexPath(for: self, localIndexPath: indexPath)
            
            return self.container.dequeueReusableCellWithIdentifier(String(ReusableCellType.self), forIndexPath: indexPath) as! ReusableCellType
        }
        
        public final func dequeueReusableHeaderView<ReusableHeaderViewType: UITableViewHeaderFooterView>(for indexPath: NSIndexPath) -> ReusableHeaderViewType {
            // let indexPath = self.parentDataSource == nil ? indexPath : self.parentDataSource!.globalIndexPath(for: self, localIndexPath: indexPath)
            
            return self.container.dequeueReusableHeaderFooterViewWithIdentifier(String(ReusableHeaderViewType.self)) as! ReusableHeaderViewType
        }
        
        public final func dequeueReusableFooterView<ReusableFooterViewType: UITableViewHeaderFooterView>(for indexPath: NSIndexPath) -> ReusableFooterViewType {
            // let indexPath = self.parentDataSource == nil ? indexPath : self.parentDataSource!.globalIndexPath(for: self, localIndexPath: indexPath)
            
            return self.container.dequeueReusableHeaderFooterViewWithIdentifier(String(ReusableFooterViewType.self)) as! ReusableFooterViewType
        }
        
    }

    // MARK: -
    
    extension FetchRequestControllerDataSource where T: UITableView {
        
        public func bind(with rowAnimation: UITableViewRowAnimation = .Fade) {
            self.fetchRequestController
                .willChangeContent { [unowned self] in
                    self.container.beginUpdates()
                }
                .didInsertSection { [unowned self] sectionInfo, newSectionIndex in
                    let newSectionIndex = self.globalSection(forLocalSection: newSectionIndex)
                    
                    self.container.insertSections(NSIndexSet(index: newSectionIndex), withRowAnimation: rowAnimation)
                }
                .didDeleteSection { [unowned self] sectionInfo, sectionIndex in
                    let sectionIndex = self.globalSection(forLocalSection: sectionIndex)
                    
                    self.container.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: rowAnimation)
                }
                .didUpdateSection { [unowned self] sectionInfo, sectionIndex in
                    let sectionIndex = self.globalSection(forLocalSection: sectionIndex)
                    
                    self.container.reloadSections(NSIndexSet(index: sectionIndex), withRowAnimation: rowAnimation)
                }
                .didInsertEntity { [unowned self] entity, newIndexPath in
                    let newIndexPath = self.globalIndexPath(forLocalIndexPath: newIndexPath)
                    
                    self.container.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: rowAnimation)
                }
                .didDeleteEntity { [unowned self] entity, indexPath in
                    let indexPath = self.globalIndexPath(forLocalIndexPath: indexPath)
                    
                    self.container.deleteRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
                }
                .didUpdateEntity { [unowned self] entity, indexPath in
                    let indexPath = self.globalIndexPath(forLocalIndexPath: indexPath)
                    
                    self.container.reloadRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
                }
                .didMoveEntity { [unowned self] entity, indexPath, newIndexPath in
                    let indexPath = self.globalIndexPath(forLocalIndexPath: indexPath)
                    let newIndexPath = self.globalIndexPath(forLocalIndexPath: newIndexPath)
                    
                    self.container.moveRowAtIndexPath(indexPath, toIndexPath: newIndexPath)
                }
                .didChangeContent { [unowned self] in
                    self.container.endUpdates()
            }
            
            try! self.fetchRequestController.performFetch()
        }
        
    }
    
    
#endif
