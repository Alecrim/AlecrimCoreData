//
//  AlecrimCoreDataError.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-07-25.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public enum AlecrimCoreDataError: Error {
    case general
    
    case notSupported
    case notImplemented
    case notHandled

    case unexpectedValue(Any)
    
    public static func handleError(_ error: Error, message: String = "Unhandled error. See callstack.") -> Never  {
        // TODO:
        self.fatalError(message)
    }
    
    public static func fatalError(_ message: String? = nil) -> Never  {
        // TODO:
        if let message = message {
            Swift.fatalError(message)
        }
        else {
            Swift.fatalError()
        }
    }
    
}
