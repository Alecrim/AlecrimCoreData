//
//  ViewController.swift
//  AlecrimCoreDataExample
//
//  Created by Vanderlei Martinelli on 2014-12-01.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Cocoa
import AlecrimCoreData

class ViewController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    
    lazy var arrayController: NSArrayController = {
        return dataContext.events.orderByDescending("timeStamp").toArrayController()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.setDelegate(self)
        
        self.tableView.bind(NSContentBinding, toObject: self.arrayController, withKeyPath: "arrangedObjects", options: nil)
        self.tableView.bind(NSSelectionIndexesBinding, toObject: self.arrayController, withKeyPath: "selectionIndexes", options: nil)
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func add(sender: AnyObject) {
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
    
    func remove(sender: AnyObject) {
        if let entity = self.arrayController.selectedObjects.first as? EventEntity {
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

//        // OR delete entity using main thread data context.
//        if let entity = self.arrayController.selectedObjects.first as? EventEntity {
//            dataContext.events.deleteEntity(entity)
//            
//            if !dataContext.save() {
//                // Replace this implementation with code to handle the error appropriately.
//                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//                abort()
//            }
//        }
    }
    
}

extension ViewController: NSTableViewDelegate {
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeViewWithIdentifier(tableColumn!.identifier!, owner: tableView.delegate()) as? NSView
        
        if let v = view {
            if let textField = view?.subviews.first as? NSTextField {
                textField.bind(NSValueBinding, toObject:v, withKeyPath:"objectValue.timeStamp", options: nil)
            }
        }
        
        return view
    }
    
}

extension ViewController { //: NSToolbarItemValidation {
    
    override func validateToolbarItem(theItem: NSToolbarItem) -> Bool {
        return theItem.enabled
    }
    
}
