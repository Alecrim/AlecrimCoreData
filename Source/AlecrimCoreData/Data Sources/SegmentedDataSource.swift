//
//  SegmentedDataSource.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-06-04.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation

public /* abstract */ class SegmentedDataSource<T: Container, C: ContainerCell>: DataSource<T, C> {
    
    // MARK: -
    
    public let dataSources: [DataSource<T, C>]
    
    private var _selectedDataSource: DataSource<T, C>? = nil
    public var selectedDataSource: DataSource<T, C>? {
        get { return self._selectedDataSource }
        set {
            self._selectedDataSource = newValue
            
            if let newValue = newValue {
                self._selectedDataSourceIndex = self.dataSources.indexOf(newValue) ?? -1
            }
            else {
                self._selectedDataSourceIndex = -1
            }
        }
    
    }
    
    private var _selectedDataSourceIndex: Int = -1
    public var selectedDataSourceIndex: Int {
        get { return self._selectedDataSourceIndex }
        set {
            self._selectedDataSourceIndex = newValue
            
            if newValue >= 0 {
                self._selectedDataSource = self.dataSources[newValue]
            }
            else {
                self._selectedDataSource = nil
            }
        }
    }
    
    // MARK: -
    
    public init(for container: T, dataSources: [DataSource<T, C>]) {
        self.dataSources = dataSources
        super.init(for: container)
    }
    
    // MARK: -
    
    public override final func numberOfSections() -> Int {
        return self.selectedDataSource?.numberOfSections() ?? 0
    }
    
    public override final func numberOfItems(inSection section: Int) -> Int {
        return self.selectedDataSource?.numberOfItems(inSection: section) ?? 0
    }
    
    public override final func cellForItem(at indexPath: NSIndexPath) -> C {
        return self.selectedDataSource!.cellForItem(at: indexPath)
    }
    
    public override final func configureCell(cell: C, at indexPath: NSIndexPath) {
        self.selectedDataSource!.configureCell(cell, at: indexPath)
    }
    
}
