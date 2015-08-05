//
//  iCloudDataContext.swift
//
//  Created by Vanderlei Martinelli on 2015-04-19.
//

import Foundation
import AlecrimCoreData

class iCloudDataContext: AlecrimCoreData.Context {
    
    var people:      Table<PersonEntity>     { return Table<PersonEntity>(context: self) }
    var departments: Table<DepartmentEntity> { return Table<DepartmentEntity>(context: self) }
    
    // MARK - custom init
    
    convenience init?() {
        //
        let contextOptions = ContextOptions()
        
        //
        let ubiquitousContainerIdentifier = "iCloud.com.company.MyAppName"
        let ubiquitousContentURL = NSFileManager.defaultManager().URLForUbiquityContainerIdentifier(ubiquitousContainerIdentifier)!.URLByAppendingPathComponent("CoreData", isDirectory: true)
        let ubiquitousContentName = "UbiquityStore"
        
        contextOptions.configureUbiquityOptionsWithUbiquitousContainerIdentifier(ubiquitousContainerIdentifier, ubiquitousContentURL: ubiquitousContentURL, ubiquitousContentName: ubiquitousContentName)
        
        // call designated initializer
        self.init(contextOptions: contextOptions)
        
        // here you can add observers for ubiquity notifications (AlecrimCoreData.Context is a subclass of NSManagedObjectContext)
    }
    
}
