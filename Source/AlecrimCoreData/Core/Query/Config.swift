//
//  Config.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 11/03/18.
//  Copyright © 2018 Alecrim. All rights reserved.
//

import Foundation

public struct Config {
    public static var defaultBatchSize: Int = 20
    public static var defaultComparisonOptions: NSComparisonPredicate.Options = [.caseInsensitive, .diacriticInsensitive]
}
