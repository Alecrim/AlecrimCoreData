//
//  Duplet.swift
//  AlecrimCoreData
//
//  Created by Adam Szeptycki on 2015-12-18.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

internal struct Duplet<A: Hashable, B: Hashable>: Hashable {
    let one: A
    let two: B
    
    var hashValue: Int {
        return one.hashValue ^ two.hashValue
    }
    
    init(_ one: A, _ two: B) {
        self.one = one
        self.two = two
    }
}

internal func ==<A, B> (lhs: Duplet<A, B>, rhs: Duplet<A, B>) -> Bool {
    return lhs.one == rhs.one && lhs.two == rhs.two
}
