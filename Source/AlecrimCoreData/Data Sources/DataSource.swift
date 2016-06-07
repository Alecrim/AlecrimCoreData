//
//  DataSource.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-05-21.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation

public /* abstract */ class DataSource: NSObject {
    
    public final weak var parentDataSource: DataSource? = nil
    
}

extension DataSource {
    
    internal /* abstract */ func numberOfSections() -> Int {
        fatalError()
    }
    
}

extension DataSource {
    
    public final func dataSource(atSectionIndex sectionIndex: Int) -> DataSource {
        let indexPath = NSIndexPath(forSection: sectionIndex)
        return self.dataSource(at: indexPath)
    }
    
    public func dataSource(at indexPath: NSIndexPath) -> DataSource {
        return self
    }
    
}


extension DataSource {
    
    internal func updateMappings() {
        // do nothing
    }
    
    public /* abstract */ func globalSection(forLocalSection localSection: Int) -> Int {
        fatalError()
    }
    
    public /* abstract */ func globalIndexPath(forLocalIndexPath localIndexPath: NSIndexPath) -> NSIndexPath {
        fatalError()
    }
    
    public /* abstract */ func localSection(forGlobalSection globalSection: Int) -> Int {
        fatalError()
    }
    
    public /* abstract */ func localIndexPath(forGlobalIndexPath globalIndexPath: NSIndexPath) -> NSIndexPath {
        fatalError()
    }
    
}


extension NSIndexPath {
    
    public convenience init(forSection section: Int) {
        self.init(forItem: 0, inSection: section)
    }
    
}
