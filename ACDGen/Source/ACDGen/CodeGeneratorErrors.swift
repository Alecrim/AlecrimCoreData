//
//  CodeGeneratorErrors.swift
//  ACDGen
//
//  Created by Vanderlei Martinelli on 2015-09-07.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public enum CodeGeneratorErrors: ErrorType {
    case MOMCToolNotFound
    case MOMCToolCallFailed
    case TemporaryManagedObjectModelCreationFailed
}
