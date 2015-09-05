//
//  AlecrimCoreDataError.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-25.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public enum AlecrimCoreDataError: ErrorType {
    case General
    
    case NotSupported
    case NotImplemented
    case NotHandled

    case InvalidManagedObjectModelURL
    case InvalidPersistentStoreURL

    case UnexpectedValue(value: Any)
}
