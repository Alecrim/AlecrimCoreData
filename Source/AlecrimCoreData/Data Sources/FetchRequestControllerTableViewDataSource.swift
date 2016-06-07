//
//  FetchRequestControllerTableViewDataSource.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-06-02.
//  Copyright © 2016 Alecrim. All rights reserved.
//

#if os(iOS)

import Foundation
import CoreData

public /* abstract */ class FetchRequestControllerTableViewDataSource<E: NSManagedObject>: TableViewDataSource {
    
    public final let fetchRequestController: FetchRequestController<E>
    
    public init(tableView: UITableView, fetchRequestController: FetchRequestController<E>) {
        self.fetchRequestController = fetchRequestController
        super.init(tableView: tableView)
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
    
    // MARK: -
    
    public override final func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchRequestController.numberOfSections()
    }
    
    public override final func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchRequestController.numberOfEntities(inSection: section)
    }

    
}
extension FetchRequestControllerTableViewDataSource {
    
    public final func bind(with rowAnimation: UITableViewRowAnimation = .Fade) {
        self.fetchRequestController
            .willChangeContent { [unowned self] in
                self.beginUpdates()
            }
            .didInsertSection { [unowned self] sectionInfo, newSectionIndex in
                self.insertSections(NSIndexSet(index: newSectionIndex), with: rowAnimation)
            }
            .didDeleteSection { [unowned self] sectionInfo, sectionIndex in
                self.deleteSections(NSIndexSet(index: sectionIndex), with: rowAnimation)
            }
            .didUpdateSection { [unowned self] sectionInfo, sectionIndex in
                self.reloadSections(NSIndexSet(index: sectionIndex), with: rowAnimation)
            }
            .didInsertEntity { [unowned self] entity, newIndexPath in
                self.insertRows(at: [newIndexPath], with: rowAnimation)
            }
            .didDeleteEntity { [unowned self] entity, indexPath in
                self.deleteRows(at: [indexPath], withRowAnimation: rowAnimation)
            }
            .didUpdateEntity { [unowned self] entity, indexPath in
                self.reloadRows(at: [indexPath], withRowAnimation: rowAnimation)
            }
            .didMoveEntity { [unowned self] entity, indexPath, newIndexPath in
                self.moveRow(at: indexPath, to: newIndexPath)
            }
            .didChangeContent { [unowned self] in
                self.endUpdates()
        }
        
        try! self.fetchRequestController.performFetch()
    }
    
}

#endif
