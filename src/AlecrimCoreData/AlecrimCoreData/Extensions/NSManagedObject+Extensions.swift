//
//  NSManagedObject+Extensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-24.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// #pragma mark - Entity Information

extension NSManagedObject {
    
    // TODO: change to class var
    class func getEntityName() -> String {
        let className: NSString = NSStringFromClass(self.classForCoder())
        
        //if className.hasSuffix(".Entity") {
        //    return className
        //}
        
        let range = className.rangeOfString("Entity")
            
        if range.location == NSNotFound || range.location == 0 {
            return className;
        }
        else {
            return className.substringToIndex(range.location)
        }
    }

}
