//
//  CodeGeneratorErrors.swift
//  ACDGen
//
//  Created by Vanderlei Martinelli on 2015-09-07.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public enum CodeGeneratorError: Error {
    case momcToolNotFound
    case momcToolCallFailed
    case temporaryManagedObjectModelCreationFailed
}
