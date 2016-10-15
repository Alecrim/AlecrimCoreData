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

let persistentContainer = (UIApplication.shared.delegate! as! AppDelegate).persistentContainer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        // Override point for customization after application launch.
        self.addInitialData()
        
        //
        return true
    }

    // MARK: - Core Data stack
    
    fileprivate private(set) lazy var persistentContainer: PersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = PersistentContainer(name: "ACD_Alarm")
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as? NSError {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        return container
    }()
    
    // MARK: -
    
    private func addInitialData() {
        self.persistentContainer.performBackgroundTask { backgroundContext in
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

