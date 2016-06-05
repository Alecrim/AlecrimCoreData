//
//  DataSource.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-05-21.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

public protocol Container: NSObjectProtocol {
}

public protocol ContainerCell: NSObjectProtocol {
}

// MARK: -

public /* abstract */ class DataSource<T: Container, C: ContainerCell>: NSObject {
    
    // MARK: -

    public final let container: T

    internal final weak var parentDataSource: ComposedDataSource<T, C>? = nil
    
    // MARK: -
    
    public init(for container: T) {
        self.container = container
        super.init()
    }
    
    // MARK: -
    
    public /* abstract */ func numberOfSections() -> Int {
        fatalError()
    }
    
    public /* abstract */ func numberOfItems(inSection section: Int) -> Int {
        fatalError()
    }
    
    public /* abstract */ func cellForItem(at indexPath: NSIndexPath) -> C {
        fatalError()
    }
    
    // MARK: -
    
    public /* abstract */ func configureCell(cell: C, at indexPath: NSIndexPath) {
        fatalError()
    }

}

extension DataSource {
    
    public final func globalSection(forLocalSection localSection: Int) -> Int {
        return self.parentDataSource == nil ? localSection : self.parentDataSource!.globalSection(for: self, localSection: localSection)
    }
    
    public final func globalIndexPath(forLocalIndexPath localIndexPath: NSIndexPath) -> NSIndexPath {
        return self.parentDataSource == nil ? localIndexPath : self.parentDataSource!.globalIndexPath(for: self, localIndexPath: localIndexPath)
    }
    
}
