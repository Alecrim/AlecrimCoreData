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
    
    init?() {
        let contextOptions = ContextOptions(stackType: .SQLite)
        
        // only needed if model is not in main bundle
        contextOptions.modelBundle = NSBundle(forClass: DataContext.self)
        
        // only needed if entity class names are different from entity names
        contextOptions.entityClassNameSuffix = "Entity"
        
        // enable iCloud Core Data sync
        contextOptions.ubiquityEnabled = true
        
        // only needed if the identifier is different from default identifier
        contextOptions.ubiquitousContainerIdentifier = "iCloud.com.company.MyApp"
        
        // call super
        super.init(contextOptions: contextOptions)
    }
    
}
