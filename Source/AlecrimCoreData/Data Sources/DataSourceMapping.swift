//
//  DataSourceMapping.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-06-04.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation

internal final class DataSourceMapping<T: DataSource> {
    
    // MARK: -
    
    internal weak private(set) var dataSource: T!
    internal private(set) var numberOfSections: Int = 0
    
    // MARK: -
    
    private var globalToLocalSections = [Int : Int]()
    private var localToGlobalSections = [Int : Int]()
    
    // MARK: -
    
    internal init(dataSource: T) {
        self.dataSource = dataSource
    }
    
    internal convenience init(dataSource: T, globalSectionIndex: Int) {
        self.init(dataSource: dataSource)
        self.updateMappingStarting(atGlobalSection: globalSectionIndex)
    }
    
}

// MARK: -

extension DataSourceMapping {

    internal func localSection(forGlobalSection globalSection: Int) -> Int {
        return self.globalToLocalSections[globalSection]!
    }
    
    internal func globalSection(forLocalSection localSection: Int) -> Int {
        return self.localToGlobalSections[localSection]!
    }
    
    internal func localIndexPath(forGlobalIndexPath globalIndexPath: NSIndexPath) -> NSIndexPath {
        let localSection = self.localSection(forGlobalSection: globalIndexPath.section)
        
        return NSIndexPath(forItem: globalIndexPath.item, inSection: localSection)
    }
    
    internal func globalIndexPath(forLocalIndexPath localIndexPath: NSIndexPath) -> NSIndexPath {
        let globalSection = self.globalSection(forLocalSection: localIndexPath.section)
        
        return NSIndexPath(forItem: localIndexPath.item, inSection: globalSection)
    }
    
    internal func localIndexPaths(forGlobalIndexPaths globalIndexPaths: [NSIndexPath]) -> [NSIndexPath] {
        return globalIndexPaths.map { self.localIndexPath(forGlobalIndexPath: $0) }
    }
    
    internal func globalIndexPaths(forLocalIndexPaths localIndexPaths: [NSIndexPath]) -> [NSIndexPath] {
        return localIndexPaths.map { self.globalIndexPath(forLocalIndexPath: $0) }
    }
    
    internal func updateMappingStarting(atGlobalSection globalSection: Int, with closure: ((Int) -> Void)? = nil) {
        var globalSection = globalSection
        
        self.numberOfSections = self.dataSource.numberOfSections()
        self.globalToLocalSections.removeAll()
        self.localToGlobalSections.removeAll()
        
        for localSection in 0..<self.numberOfSections {
            self.addMapping(fromGlobalSection: globalSection, toLocalSection: localSection)
            closure?(globalSection)
            globalSection += 1
        }
    }
    
}

// MARK: -

extension DataSourceMapping {
    
    private func addMapping(fromGlobalSection globalSection: Int, toLocalSection localSection: Int) {
        assert(self.globalToLocalSections[globalSection] == nil, "Collision while trying to add to a mapping.")
        assert(self.localToGlobalSections[localSection] == nil, "Collision while trying to add to a mapping.")
        
        self.globalToLocalSections[globalSection] = localSection
        self.localToGlobalSections[localSection] = globalSection
    }
    
}
