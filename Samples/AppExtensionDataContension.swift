//
//  AppExtensionDataContension.swift
//
//  Created by Vanderlei Martinelli on 2015-05-09.
//

import Foundation
import AlecrimCoreData

class DataContext: AlecrimCoreData.Context {
    
    var people:      Table<PersonEntity>     { return Table<PersonEntity>(context: self) }
    var departments: Table<DepartmentEntity> { return Table<DepartmentEntity>(context: self) }
    
    // MARK - custom init
    
    init?() {
        let contextOptions = ContextOptions(stackType: .SQLite)
        
        // only needed if entity class names are different from entity names
        contextOptions.entityClassNameSuffix = "Entity"
        
        // needed as your model probably is not in the main bundle
        contextOptions.modelBundle = NSBundle(forClass: DataContext.self)
        
        // set the managed object model name, usually the same name as the main app name
        contextOptions.managedObjectModelName = "MyModelName"
        
        // must be set to not infer from main bundle
        contextOptions.persistentStoreRelativePath = "com.company.MyAppName/CoreData"
        
        // the same identifier used to group your main app and its extensions
        contextOptions.applicationGroupIdentifier = "group.com.company.MyAppName"
        
        // call super
        super.init(contextOptions: contextOptions)
    }
    
}
