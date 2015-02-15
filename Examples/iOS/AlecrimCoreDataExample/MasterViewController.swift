//
//  MasterViewController.swift
//  AlecrimCoreDataExample
//
//  Created by Vanderlei Martinelli on 2014-11-30.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import UIKit
import CoreData
import AlecrimCoreData

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    
    lazy var fetchedResultsController: FetchedResultsController<EventEntity> = {
        let frc = dataContext.events.orderByDescending("timeStamp").toFetchedResultsController()
        frc.bindToTableView(self.tableView)
        
        return frc
    }()

    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.navigationItem.leftBarButtonItem = self.editButtonItem()

        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = controllers[controllers.count-1].topViewController as? DetailViewController
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func insertNewObject(sender: AnyObject) {
        // Insert new entity using background data context for example purpose (it would be inserted using the main thread data context too).
        performInBackground(dataContext) { backgroundDataContext in
            let newEventEntity = backgroundDataContext.events.createEntity()
            
            // Configure the new managed object.
            newEventEntity.timeStamp = NSDate()
            
            // Save the background data context.
            let (success, error) = backgroundDataContext.save()
            if !success {
                // Replace this implementation with code to handle the error appropriately.
                println("Unresolved error \(error), \(error?.userInfo)")
            }
        }
        
//        // OR insert new entity using main data context.
//        let newEventEntity = dataContext.events.createEntity()
//        
//        // Configure the new managed object.
//        newEventEntity.timeStamp = NSDate()
//        
//        // Save the background data context.
//        let (success, error) = dataContext.save()
//        if !success {
//            // Replace this implementation with code to handle the error appropriately.
//            println("Unresolved error \(error), \(error?.userInfo)")
//        }
        
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
            let entity = self.fetchedResultsController.entityAtIndexPath(indexPath)
                let controller = (segue.destinationViewController as UINavigationController).topViewController as DetailViewController
                controller.detailItem = entity
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as UITableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            
            // Delete entity using a background data context.
            if let entity = self.fetchedResultsController.entityAtIndexPath(indexPath) {
                performInBackground(dataContext) { backgroundDataContext in
                    let backgroundEntity = entity.inContext(backgroundDataContext)
                    backgroundDataContext.events.deleteEntity(backgroundEntity!)
                    
                    if !backgroundDataContext.save() {
                        // Replace this implementation with code to handle the error appropriately.
                        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                        abort()
                    }
                }
            }
            
//            // OR delete entity using main thread data context.
//            if let entity = self.fetchedResultsController.entityAtIndexPath(indexPath) {
//                dataContext.events.deleteEntity(entity)
//                
//                if !dataContext.save() {
//                    // Replace this implementation with code to handle the error appropriately.
//                    // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                    abort()
//                }
//            }
            
        }
    }

    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let entity = self.fetchedResultsController.entityAtIndexPath(indexPath)
        cell.textLabel?.text = entity.timeStamp.description
    }

}

