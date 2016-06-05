//
//  FetchRequestControllerDataSource.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-06-02.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public /* abstract */ class FetchRequestControllerDataSource<T: Container, C: ContainerCell, E: NSManagedObject>: DataSource<T, C> {
    
    public final let fetchRequestController: FetchRequestController<E>
    
    public init(for container: T, fetchRequestController: FetchRequestController<E>) {
        self.fetchRequestController = fetchRequestController
        super.init(for: container)
    }
    
    public override final func numberOfSections() -> Int {
        return self.fetchRequestController.numberOfSections()
    }
    
    public override final func numberOfItems(inSection section: Int) -> Int {
        return self.fetchRequestController.numberOfEntities(inSection: section)
    }
    
    //
    
    public final func section(atIndex sectionIndex: Int) -> FetchRequestControllerSection<E> {
        return self.fetchRequestController.sections[sectionIndex]
    }
    
    public final func entity(at indexPath: NSIndexPath) -> E {
        return self.fetchRequestController.entity(at: indexPath)
    }
    
    public final func indexPath(for entity: E) -> NSIndexPath? {
        return self.fetchRequestController.indexPath(for: entity)
    }
    
}
