//
//  FetchAsyncHandler.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-06-05.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public final class FetchAsyncHandler: NSObject {
    
    dynamic public private(set) var cancelled: Bool = false {
        didSet {
            if self.cancelled {
                self.asynchronousFetchResult?.cancel()
            }
        }
    }
    
    dynamic public private(set) var fractionCompleted: Double = 0.0
    
    private let asynchronousFetchRequest: NSAsynchronousFetchRequest
    
    private var fractionCompletedObserverAdded = false
    
    // needed to force asynchronousFetchResult to create and assign its own NSProgress,
    // used in Context.executeAsynchronousFetchRequestWithFetchRequest
    internal lazy var foolProgress: NSProgress = { return NSProgress(totalUnitCount: 1) }()
    
    internal var asynchronousFetchResult: NSAsynchronousFetchResult? {
        didSet {
            if let asynchronousFetchResult = self.asynchronousFetchResult {
                asynchronousFetchResult.addObserver(self, forKeyPath: "progress", options: (.Initial | .New), context: nil)
            }
        }
    }
    
    internal init(asynchronousFetchRequest: NSAsynchronousFetchRequest) {
        self.asynchronousFetchRequest = asynchronousFetchRequest
    }
    
    deinit {
        if self.fractionCompletedObserverAdded {
            self.asynchronousFetchResult?.progress?.removeObserver(self, forKeyPath: "fractionCompleted", context: nil)
        }
        
        self.asynchronousFetchResult?.removeObserver(self, forKeyPath: "progress", context: nil)
    }
    
    public func cancel() {
        self.cancelled = true
    }
    
    public override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if let asynchronousFetchResult = self.asynchronousFetchResult where asynchronousFetchResult == object as! NSObject {
            if keyPath == "progress" {
                if let progress = change[NSKeyValueChangeNewKey] as? NSProgress {
                    if self.fractionCompletedObserverAdded == false {
                        progress.addObserver(self, forKeyPath: "fractionCompleted", options: (.Initial | .New), context: nil)
                        self.fractionCompletedObserverAdded = true
                    }
                }
            }
        }
        else if let progress = self.asynchronousFetchResult?.progress where progress == object as! NSObject {
            if keyPath == "fractionCompleted" {
                if let fractionCompletedNumber = change[NSKeyValueChangeNewKey] as? NSNumber {
                    self.fractionCompleted = fractionCompletedNumber.doubleValue
                }
            }
        }
    }

}
