//
//  EnsemblesDataContext.swift
//
//  Created by Vanderlei Martinelli on 2015-04-19.
//

import Foundation
import AlecrimCoreData
import Ensembles

class EnsemblesDataContext: AlecrimCoreData.Context {
    
    var people:      Table<PersonEntity>     { return Table<PersonEntity>(context: self) }
    var departments: Table<DepartmentEntity> { return Table<DepartmentEntity>(context: self) }
    
    // MARK: - ensembles support
    
    var cloudFileSystem: CDEICloudFileSystem! = nil
    var ensemble: CDEPersistentStoreEnsemble! = nil
    var ensembleDelegate: EnsembleDelegate! = nil
    
    var obs1: AnyObject! = nil
    var obs2: AnyObject! = nil
    
    // MARK - custom init
    
    convenience init?() {
        let contextOptions = ContextOptions()
        self.init(contextOptions: contextOptions)
        
        // configure Ensembles
        self.cloudFileSystem = CDEICloudFileSystem(ubiquityContainerIdentifier: "iCloud.com.company.MyApp")
        self.ensemble = CDEPersistentStoreEnsemble(
            ensembleIdentifier: "EnsembleStore",
            persistentStoreURL: contextOptions.persistentStoreURL,
            managedObjectModelURL: contextOptions.managedObjectModelURL,
            cloudFileSystem: self.cloudFileSystem
        )
        
        // assign delegate
        self.ensembleDelegate = EnsembleDelegate(managedObjectContext: self)
        self.ensemble.delegate = self.ensembleDelegate
        
        // set observers
        self.obs1 = NSNotificationCenter.defaultCenter().addObserverForName(CDEMonitoredManagedObjectContextDidSaveNotification, object: nil, queue: nil) { [unowned self] notification in
            self.sync()
        }
        
        self.obs2 = NSNotificationCenter.defaultCenter().addObserverForName(CDEICloudFileSystemDidDownloadFilesNotification, object: nil, queue: nil) { [unowned self] notification in
            self.sync()
        }
        
        // initial sync
        self.sync()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self.obs1)
        NSNotificationCenter.defaultCenter().removeObserver(self.obs2)
    }
    
    func sync() {
        if self.ensemble.leeched {
            self.ensemble.mergeWithCompletion { error in
                if let error = error {
                    println(error)
                }
            }
        }
        else {
            self.ensemble.leechPersistentStoreWithCompletion { error in
                if let error = error {
                    println(error)
                }
            }
        }
    }
}

class EnsembleDelegate: NSObject, CDEPersistentStoreEnsembleDelegate  {
    
    let managedObjectContext: NSManagedObjectContext
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }
    
    @objc func persistentStoreEnsemble(ensemble: CDEPersistentStoreEnsemble, didSaveMergeChangesWithNotification notification: NSNotification) {
        var currentContext: NSManagedObjectContext? = self.managedObjectContext
        
        while let c = currentContext {
            c.performBlockAndWait {
                c.mergeChangesFromContextDidSaveNotification(notification)
            }
            
            currentContext = currentContext?.parentContext
        }
    }
    
    @objc func persistentStoreEnsemble(ensemble: CDEPersistentStoreEnsemble, globalIdentifiersForManagedObjects objects: [AnyObject]) -> [AnyObject] {
        return (objects as NSArray).valueForKeyPath("uniqueIdentifier") as! [AnyObject]
    }
    
}
