//
//  Event.swift
//  AlecrimCoreDataExample
//
//  Created by Vanderlei Martinelli on 2014-11-30.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData
import AlecrimCoreData

class Event: NSManagedObject {

    @NSManaged var timeStamp: NSDate
    
}

extension Event {
    
    static let timeStamp = AlecrimCoreData.Attribute<NSDate>("timeStamp")
    
}
