//
//  CoreDataTable+Extensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-07-18.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension CoreDataTable {
    
    public func toFetchedResultsController(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> CoreDataFetchedResultsController<T> {
        return CoreDataFetchedResultsController<T>(fetchRequest: self.toFetchRequest(), managedObjectContext: self.context, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

}

extension CoreDataTable {

    public func bindTo(#tableView: UITableView) -> CoreDataFetchedResultsController<T> {
        return self.toFetchedResultsController().bindTo(tableView: tableView)
    }

}