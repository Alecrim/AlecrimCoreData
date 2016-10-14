//
//  AlarmTableViewController.swift
//  ACD Alarm
//
//  Created by Vanderlei Martinelli on 2016-08-11.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import UIKit
import CoreData

import AlecrimCoreData

class AlarmTableViewController: UITableViewController {
    
    // MARK :-
    
    fileprivate private(set) lazy var fetchRequestController: FetchRequestController<Alarm> = {
        let query = persistentContainer.viewContext.alarms.orderBy { $0.date }
        
        return query.toFetchRequestController()
    }()

    fileprivate private(set) lazy var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        
        return df
    }()

    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        self.clearsSelectionOnViewWillAppear = true
        self.tableView.allowsSelectionDuringEditing = true
        self.navigationItem.leftBarButtonItem = self.editButtonItem
        
        //
        self.fetchRequestController.bind(to: self.tableView)
        
        //
        self.fetchRequestController
            .didInsertObject { [weak self] _, _ in
                self?.checkEnabledControls()
            }
            .didDeleteObject { [weak self] _, _ in
                self?.checkEnabledControls()
            }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.checkEnabledControls()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "AddAlarm":
            if let vc = (segue.destination as? UINavigationController)?.topViewController as? AlarmEditViewController {
                vc.alarm = nil
            }
            
        case "EditAlarm":
            if let vc = (segue.destination as? UINavigationController)?.topViewController as? AlarmEditViewController {
                vc.alarm = self.fetchRequestController.object(at: self.tableView.indexPathForSelectedRow!)
            }
            
        default:
            break
            
        }
    }
    
    @IBAction func prepareForUnwind(segue: UIStoryboardSegue) {
        self.isEditing = false
    }
    
    // MARK: -
    
    private func checkEnabledControls() {
        if self.fetchRequestController.numberOfObjects(inSection: 0) > 0 {
            self.editButtonItem.isEnabled = true
        }
        else {
            self.isEditing = false
            self.editButtonItem.isEnabled = false
        }
    }
    
}

// MARK: - UITableViewDataSource

extension AlarmTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.fetchRequestController.numberOfSections()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fetchRequestController.numberOfObjects(inSection: section)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmCell", for: indexPath)
        let alarm = self.fetchRequestController.object(at: indexPath)
        
        cell.textLabel!.text = self.dateFormatter.string(from: alarm.date)
        cell.detailTextLabel!.text = alarm.type.name + " " + alarm.label
        
        return cell
    }
    
}

// MARK: - UITableViewDelegate

extension AlarmTableViewController {
    
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return self.isEditing ? indexPath : nil
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alarm = self.fetchRequestController.object(at: indexPath)
            
            persistentContainer.performBackgroundTask { backgroundContext in
                let alarm = try! alarm.inContext(backgroundContext)
                
                alarm.delete()
                
                try! backgroundContext.save()
            }
        }
    }
    
}


