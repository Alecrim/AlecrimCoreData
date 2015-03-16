//
//  FetchedResultsController+Extensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-08-10.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import UIKit

// MARK: - UITableView helper methods

extension FetchedResultsController {
    
    public func bindToTableView(tableView: UITableView, rowAnimation: UITableViewRowAnimation = .Fade) -> Self {
        self
            .willChangeContent { [unowned tableView] in
                tableView.beginUpdates()
            }
            .didInsertSection { [unowned tableView] sectionInfo, sectionIndex in
                tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: rowAnimation)
            }
            .didDeleteSection { [unowned tableView] sectionInfo, sectionIndex in
                tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: rowAnimation)
            }
            .didInsertEntity { [unowned tableView] entity, newIndexPath in
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: rowAnimation)
            }
            .didDeleteEntity { [unowned tableView] entity, indexPath in
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
            }
            .didUpdateEntity { [unowned tableView] entity, indexPath in
                tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
            }
            .didMoveEntity { [unowned tableView] entity, indexPath, newIndexPath in
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: rowAnimation)
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: rowAnimation)
            }
            .didChangeContent { [unowned tableView] in
                tableView.endUpdates()
        }
        
        return self
    }
    
}

