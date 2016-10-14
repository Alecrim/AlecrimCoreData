//
//  Enumerable.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-06-17.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public protocol Enumerable: Sequence {
    
    var offset: Int { get set }
    var limit: Int { get set }

    func count() -> Int

}

// MARK: -

extension Enumerable {
    
    public final func skip(_ count: Int) -> Self {
        var clone = self
        clone.offset = count
        
        return clone
    }
    
    public final func take(_ count: Int) -> Self {
        var clone = self
        clone.limit = count
        
        return clone
    }
    
}

extension Enumerable {
    
    public final func any() -> Bool {
        return self.take(1).count() == 1
    }
    
    public final func none() -> Bool {
        return !self.any()
    }
    
}
