//
//  FetchedResultsSectionInfo.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-08-09.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

#if os(iOS)
    
import Foundation
import CoreData

public final class FetchedResultsSectionInfo<T: NSManagedObject> {
    
    private let underlyingSectionInfo: NSFetchedResultsSectionInfo
    
    public var name: String! { return self.underlyingSectionInfo.name }
    public var indexTitle: String! { return self.underlyingSectionInfo.indexTitle }
    public var numberOfObjects: Int { return self.underlyingSectionInfo.numberOfObjects }
    public var entities: [T]! { return self.underlyingSectionInfo.objects as? [T] }
    
    internal init(underlyingSectionInfo: NSFetchedResultsSectionInfo) {
        self.underlyingSectionInfo = underlyingSectionInfo
    }
    
}

#endif
