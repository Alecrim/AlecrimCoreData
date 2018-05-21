//
//  FetchRequestController+Extensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 21/04/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

extension FetchRequestController {

    internal enum Change<T> {
        case insert(T)
        case delete(T)
        case update(T)
        case move(T, T) // from, to
    }
    
}
