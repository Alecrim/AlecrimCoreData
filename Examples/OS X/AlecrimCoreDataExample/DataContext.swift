//
//  DataContext.swift
//  AlecrimCoreDataExample
//
//  Created by Vanderlei Martinelli on 2014-11-30.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import AlecrimCoreData

let dataContext = DataContext()!

final class DataContext: AlecrimCoreData.Context {

    var events: AlecrimCoreData.Table<EventEntity> { return AlecrimCoreData.Table<EventEntity>(context: self) }
    
}