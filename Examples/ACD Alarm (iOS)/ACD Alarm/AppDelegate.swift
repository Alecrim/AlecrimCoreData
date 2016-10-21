//
//  AppDelegate.swift
//  ACD Alarm
//
//  Created by Vanderlei Martinelli on 2016-08-11.
//  Copyright © 2016 Alecrim. All rights reserved.
//

import UIKit
import CoreData

import AlecrimCoreData

// the global persistent container
let persistentContainer = PersistentContainer(name: "ACD_Alarm")

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // Override point for customization after application launch.
        self.addInitialData()
        
        //
        return true
    }
    
    //
    
    private func addInitialData() {
        persistentContainer.performBackgroundTask { backgroundContext in
            func addAlarmType(withIdentifier identifier: String, name: String) {
                var alarmType: AlarmType! = backgroundContext.alarmTypes.first { $0.identifier == identifier }
                
                if alarmType == nil {
                    alarmType = backgroundContext.alarmTypes.create()
                    alarmType.identifier = identifier
                }
                
                alarmType.name = name
            }
            
            //
            addAlarmType(withIdentifier: "home", name: "Home")
            addAlarmType(withIdentifier: "work", name: "Work")
            
            //
            try! backgroundContext.save()
        }
    }

}

