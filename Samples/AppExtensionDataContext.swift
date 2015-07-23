//
//  AppExtensionDataContext.swift
//
//  Created by Vanderlei Martinelli on 2015-05-09.
//

import Foundation
import AlecrimCoreData

class AppExtensionDataContext: AlecrimCoreData.Context {
    
    var people:      Table<PersonEntity>     { return Table<PersonEntity>(context: self) }
    var departments: Table<DepartmentEntity> { return Table<DepartmentEntity>(context: self) }
    
    // MARK - custom init
    
    convenience init?() {
        let contextOptions = ContextOptions(managedObjectModelBundle: NSBundle(forClass: AppExtensionDataContext.self), applicationGroupIdentifier: "group.com.company.MyAppName")
        self.init(contextOptions: contextOptions)
    }
    
}
