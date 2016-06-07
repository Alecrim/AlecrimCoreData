//
//  AbstractDataSource.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-05-21.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation

public /* abstract */ class AbstractDataSource: NSObject {
    
    public final weak var parentDataSource: AbstractDataSource? = nil
    
}

extension AbstractDataSource {
    
    internal /* abstract */ func numberOfSections() -> Int {
        fatalError()
    }
    
}

extension AbstractDataSource {
    
    public final func dataSource(atSectionIndex sectionIndex: Int) -> AbstractDataSource {
        let indexPath = NSIndexPath(forSection: sectionIndex)
        return self.dataSource(at: indexPath)
    }
    
    public func dataSource(at indexPath: NSIndexPath) -> AbstractDataSource {
        return self
    }
    
}


extension AbstractDataSource {
    
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
