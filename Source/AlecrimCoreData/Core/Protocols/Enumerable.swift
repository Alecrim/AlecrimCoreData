//
//  Enumerable.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-06-17.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public protocol Enumerable: SequenceType {
    
    var offset: Int { get set }
    var limit: Int { get set }

    func count() -> Int

}

// MARK: -

extension Enumerable {
    
    public func skip(count: Int) -> Self {
        var clone = self
        clone.offset = count
        
        return clone
    }
    
    public func take(count: Int) -> Self {
        var clone = self
        clone.limit = count
        
        return clone
    }
    
}

extension Enumerable {
    
    public func any() -> Bool {
        return self.take(1).count() == 1
    }
    
    public func none() -> Bool {
        return !self.any()
    }
    
}
