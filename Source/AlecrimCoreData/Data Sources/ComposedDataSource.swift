//
//  ComposedDataSource.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-05-22.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation

public /* abstract */ class ComposedDataSource<T: Container, C: ContainerCell>: DataSource<T, C> {
    
    // MARK: -

    private var mappings = [DataSourceMapping<T, C>]()
    private let dataSourceToMappings = NSMapTable(keyOptions: .ObjectPointerPersonality, valueOptions: .StrongMemory, capacity: 1)
    private var globalSectionToMappings = [Int : DataSourceMapping<T, C>]()
    
    //
    
    private var _numberOfSections = 0
    
    // MARK: -
    
    public let dataSources: [DataSource<T, C>]

    // MARK: -

    public init(for container: T, dataSources: [DataSource<T, C>]) {
        self.dataSources = dataSources
        super.init(for: container)
        
        self.dataSources.forEach { dataSource in
            let mappingForDataSource = DataSourceMapping(dataSource: dataSource)
            self.mappings.append(mappingForDataSource)
            self.dataSourceToMappings.setObject(mappingForDataSource, forKey: dataSource)
            
            dataSource.parentDataSource = self
        }
        
        self.updateMappings()
    }

    // MARK: -

    public override final func numberOfSections() -> Int {
        self.updateMappings()
        
        return self._numberOfSections
    }
    
    public override final func numberOfItems(inSection section: Int) -> Int {
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
        return dataSource.numberOfItems(inSection: localSection)
    }
    
    public override final func cellForItem(at indexPath: NSIndexPath) -> C {
        //
        let mapping = self.mapping(forGlobalSection: indexPath.section)
        let dataSource = mapping.dataSource
        let localIndexPath = mapping.localIndexPath(forGlobalIndexPath: indexPath)
        
        //
        return dataSource.cellForItem(at: localIndexPath)
    }
    
    public override final func configureCell(cell: C, at indexPath: NSIndexPath) {
        //
        let mapping = self.mapping(forGlobalSection: indexPath.section)
        let dataSource = mapping.dataSource
        let localIndexPath = mapping.localIndexPath(forGlobalIndexPath: indexPath)
        
        //
        dataSource.configureCell(cell, at: localIndexPath)
    }
    
}

extension ComposedDataSource {
    
    internal func globalSection(for dataSource: DataSource<T, C>, localSection: Int) -> Int {
        return self.mapping(for: dataSource).globalSection(forLocalSection: localSection)
    }
    
    internal func globalIndexPath(for dataSource: DataSource<T, C>, localIndexPath: NSIndexPath) -> NSIndexPath {
        return self.mapping(for: dataSource).globalIndexPath(forLocalIndexPath: localIndexPath)
    }

}

extension ComposedDataSource {
    
    private func mapping(forGlobalSection section: Int) -> DataSourceMapping<T, C> {
        return self.globalSectionToMappings[section]!
    }
    
    private func mapping(for dataSource: DataSource<T, C>) -> DataSourceMapping<T, C> {
        return self.dataSourceToMappings.objectForKey(dataSource) as! DataSourceMapping<T, C>
    }
    
}

extension ComposedDataSource {

    private func updateMappings() {
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
