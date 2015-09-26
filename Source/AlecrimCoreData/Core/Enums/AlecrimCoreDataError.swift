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
    
    @noreturn
    public static func handleError(error: ErrorType, message: String = "Unhandled error. See callstack.") {
        // TODO:
        self.fatalError(message)
    }
    
    @noreturn
    public static func fatalError(message: String? = nil) {
        // TODO:
        if let message = message {
            Swift.fatalError(message)
        }
        else {
            Swift.fatalError()
        }
    }
    
}
