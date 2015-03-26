//
//  Config.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-02-26.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation

public final class Config {
    
    public static var fetchBatchSize = 20
    
    public static var stringComparisonPredicateOptions = (NSComparisonPredicateOptions.CaseInsensitivePredicateOption | NSComparisonPredicateOptions.DiacriticInsensitivePredicateOption)
    
    public static var entityClassNamePrefix: String? = nil
    public static var entityClassNameSuffix: String? = "Entity"
    
    public static var iCloudEnabled = false
    public static var ubiquitousContentName = "UbiquityStore"
    public static var ubiquitousContentURL = "Data/TransactionLogs"
    
    public static var migratePersistentStoresAutomatically = true
    public static var inferMappingModelAutomaticallyOption = true
    
    internal static var cachedEntityNames = Dictionary<String, String>()
    
}
