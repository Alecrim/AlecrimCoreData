//
//  AlarmEditViewController.swift
//  ACD Alarm
//
//  Created by Vanderlei Martinelli on 2016-08-12.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import UIKit

import CoreData
import AlecrimCoreData

class AlarmEditViewController: UIViewController {
    
    // MARK: -
    
    internal var alarm: Alarm?
    
    // MARK: -
    
    @IBOutlet weak var datePicker: UIDatePicker!

    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        if let alarm = self.alarm {
            self.navigationItem.title = "Edit Alarm"
            self.datePicker.date = alarm.date
        }
        else {
            self.navigationItem.title = "Add Alarm"
            self.datePicker.date = Date()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case "SaveUnwindSegue":
            if let alarm = self.alarm {
                self.fillAndSaveAlarm(alarm)
            }
            else {
                self.fillAndSaveAlarm(nil)
            }
            
        default:
            break
        }
    }
    
}

extension AlarmEditViewController {
    
    fileprivate func fillAndSaveAlarm(_ alarm: Alarm?) {
        persistentContainer.performBackgroundTask { backgroundContext in
            let alarm = try! alarm?.inContext(backgroundContext) ?? backgroundContext.alarms.create()
            
            if alarm.isInserted {
                alarm.identifier = UUID().uuidString
            }
            
            alarm.type = backgroundContext.alarmTypes.first({ $0.identifier == "home" })!
            alarm.label = "Alarm"
            alarm.isActive = true
            
            alarm.date = self.datePicker.date
            
            try! backgroundContext.save()
        }
        
    }
    
}
