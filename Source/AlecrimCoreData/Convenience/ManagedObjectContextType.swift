//
//  ManagedObjectContextType.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 07/06/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

// MARK: -

extension ManagedObjectContext: ManagedObjectContextType {}

// MARK: -

public protocol ManagedObjectContextType {
    func perform(_ block: @escaping () -> Void)
    func performAndWait(_ block: () -> Void)
}

extension ManagedObjectContextType {
    
    public func async<Value>(execute closure: @escaping (Self) throws -> Value, completion: @escaping ((Value?, Error?) -> Void)) {
        let context = self
        
        context.perform {
            do {
                let value = try closure(context)
                completion(value, nil)
            }
            catch {
                completion(nil, error)
            }
        }
    }
    
    public func async<Value>(execute closure: @escaping (Self) -> Value, completion: ((Value) -> Void)? = nil) {
        let context = self
        
        context.perform {
            let value = closure(context)
            completion?(value)
        }
    }
    
    @discardableResult
    public func sync<Value>(execute closure: (Self) throws -> Value) throws -> Value {
        var value: Value?
        var outError: Error?
        
        let context = self
        
        context.performAndWait {
            do {
                value = try closure(context)
            }
            catch {
                outError = error
            }
        }
        
        if let outError = outError {
            throw outError
        }
        
        return value!
    }
    
    @discardableResult
    public func sync<Value>(execute closure: (Self) -> Value) -> Value {
        var value: Value?
        
        let context = self
        
        context.performAndWait {
            value = closure(context)
        }
        
        return value!
    }
    
}
