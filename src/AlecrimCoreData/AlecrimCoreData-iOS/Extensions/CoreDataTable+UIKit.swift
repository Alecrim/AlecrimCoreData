//
//  CoreDataTable+UIKit.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-08-10.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import UIKit

extension CoreDataTable {
    
    public func bindTo(#tableView: UITableView) -> CoreDataFetchedResultsController<T> {
        return self.toFetchedResultsController().bindTo(tableView: tableView)
    }
    
}