//
//  ACDGen+StringExtensions.swift
//  ACDGen
//
//  Created by Vanderlei Martinelli on 2015-07-15.
//  Copyright © 2015 Alecrim. All rights reserved.
//

import Foundation

// MARK: - String extensions

//
//  The following extension contains code from ActiveSupportInflector
//  (https://github.com/tomafro/ActiveSupportInflector)
//
//  Copyright (c) 2009-2011 Tom Ward
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
//  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
//  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

extension String {
    
    private var pluralRules: [(String, String)] {
        return [
            (
                "$",
                "s"
            ),
            (
                "s$",
                "s"
            ),
            (
                "(ax|test)is$",
                "$1es"
            ),
            (
                "(octop|vir)us$",
                "$1i"
            ),
            (
                "(alias|status)$",
                "$1es"
            ),
            (
                "(bu)s$",
                "$1ses"
            ),
            (
                "(buffal|tomat)o$",
                "$1oes"
            ),
            (
                "([ti])um$",
                "$1a"
            ),
            (
                "sis$",
                "ses"
            ),
            (
                "(?:([lr])f)$",
                "$1ves"
            ),
            (
                "(?:(?:([^f])fe))$",
                "$1ves"
            ),
            (
                "(hive)$",
                "$1s"
            ),
            (
                "([^aeiouy]|qu)y$",
                "$1ies"
            ),
            (
                "(x|ch|ss|sh)$",
                "$1es"
            ),
            (
                "(matr|vert|ind)(?:ix|ex)$",
                "$1ices"
            ),
            (
                "([m|l])ouse$",
                "$1ice"
            ),
            (
                "^(ox)$",
                "$1en"
            ),
            (
                "(quiz)$",
                "$1zes"
            )
        ]
    }
    
    private var singularRules: [(String, String)] {
        return [
            (
                "(.)s$",
                "$1"
            ),
            (
                "(n)ews$",
                "$1ews"
            ),
            (
                "([ti])a$",
                "$1um"
            ),
            (
                "(analy|ba|diagno|parenthe|progno|synop|the)ses$",
                "$1sis"
            ),
            (
                "(^analy)ses$",
                "$1sis"
            ),
            (
                "([^f])ves$",
                "$1fe"
            ),
            (
                "(hive)s$",
                "$1"
            ),
            (
                "(tive)s$",
                "$1"
            ),
            (
                "([lr])ves$",
                "$1f"
            ),
            (
                "([^aeiouy]|qu)ies$",
                "$1y"
            ),
            (
                "series$",
                "series"
            ),
            (
                "movies$",
                "movie"
            ),
            (
                "(x|ch|ss|sh)es$",
                "$1"
            ),
            (
                "([m|l])ice$",
                "$1ouse"
            ),
            (
                "(bus)es$",
                "$1"
            ),
            (
                "(o)es$",
                "$1"
            ),
            (
                "(shoe)s$",
                "$1"
            ),
            (
                "(cris|ax|test)es$",
                "$1is"
            ),
            (
                "(octop|vir)i$",
                "$1us"
            ),
            (
                "(alias|status)es$",
                "$1"
            ),
            (
                "^(ox)en",
                "$1"
            ),
            (
                "(vert|ind)ices$",
                "$1ex"
            ),
            (
                "(matr)ices$",
                "$1ix"
            ),
            (
                "(quiz)zes$",
                "$1"
            )
        ]
    }
    
    private var irregularRules: [(String, String)] {
        return [
            (
                "person",
                "people"
            ),
            (
                "man",
                "men"
            ),
            (
                "child",
                "children"
            ),
            (
                "sex",
                "sexes"
            ),
            (
                "move",
                "moves"
            ),
            (
                "database",
                "databases"
            )
        ]
    }
    
    private var uncountableWords: [String] {
        return [
            "equipment",
            "information",
            "rice",
            "money",
            "species",
            "series",
            "fish",
            "sheep"
        ]
    }
    
    private func pluralizedLowercaseString() -> String {
        let str = self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if str == "" {
            return str;
        }
        
        if str != "" {
            let loweredStr = str.lowercaseString
            
            if self.uncountableWords.contains(loweredStr) {
                return loweredStr
            }
            else {
                for (rule, replacement) in self.irregularRules {
                    if loweredStr == rule {
                        return replacement
                    }
                }
                
                for (rule, replacement) in Array(self.pluralRules.reverse()) {
                    let regex = try! NSRegularExpression(pattern: rule, options: NSRegularExpressionOptions())
                    let range = NSMakeRange(0, (loweredStr as NSString).length)
                    
                    if regex.firstMatchInString(loweredStr, options: NSMatchingOptions(), range: range) != nil {
                        return regex.stringByReplacingMatchesInString(loweredStr, options: NSMatchingOptions(), range: range, withTemplate: replacement)
                    }
                }
            }
        }
        
        return str;
    }
    
    private func singularizedLowercaseString() -> String {
        let str = self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        
        if str != "" {
            let loweredStr = str.lowercaseString
            
            if self.uncountableWords.contains(loweredStr) {
                return loweredStr
            }
            else {
                for (replacement, rule) in self.irregularRules {
                    if loweredStr == rule {
                        return replacement
                    }
                }
                
                for (rule, replacement) in Array(self.singularRules.reverse()) {
                    let regex = try! NSRegularExpression(pattern: rule, options: NSRegularExpressionOptions())
                    let range = NSMakeRange(0, (loweredStr as NSString).length)
                    
                    if regex.firstMatchInString(loweredStr, options: NSMatchingOptions(), range: range) != nil {
                        return regex.stringByReplacingMatchesInString(loweredStr, options: NSMatchingOptions(), range: range, withTemplate: replacement)
                    }
                }
            }
        }
        
        return str
    }
    
}

extension String {
    
    func camelCasePluralized() -> String {
        var components = self.componentsSeparatedByCapitalizedLetters()
        let pluralized = NSMutableString()
        for i in 0..<components.endIndex {
            if i == components.endIndex - 1 {
                let str = components[i].pluralizedLowercaseString() as NSString
                if i > 0 {
                    let firstLetter = str.substringToIndex(1).uppercaseString
                    let otherLetters = str.substringFromIndex(1)
                    pluralized.appendString("\(firstLetter)\(otherLetters)")
                }
                else {
                    pluralized.appendString(str as String)
                }
            }
            else if i == 0 {
                pluralized.appendString(components[i].lowercaseString)
            }
            else {
                pluralized.appendString(components[i])
            }
        }
        
        return pluralized as String
    }

    func camelCaseSingularized() -> String {
        var components = self.componentsSeparatedByCapitalizedLetters()
        let singularized = NSMutableString()
        for i in 0..<components.endIndex {
            if i == components.endIndex - 1 {
                let str = components[i].singularizedLowercaseString() as NSString
                if i > 0 {
                    let firstLetter = str.substringToIndex(1).uppercaseString
                    let otherLetters = str.substringFromIndex(1)
                    singularized.appendString("\(firstLetter)\(otherLetters)")
                }
                else {
                    singularized.appendString(str as String)
                }
            }
            else if i == 0 {
                singularized.appendString(components[i].lowercaseString)
            }
            else {
                singularized.appendString(components[i])
            }
        }
        
        return singularized as String
    }

    private func componentsSeparatedByCapitalizedLetters() -> [String] {
        let newStr = (self as NSString).stringByReplacingOccurrencesOfString("([a-z])([A-Z])", withString: "$1 $2", options: NSStringCompareOptions.RegularExpressionSearch, range: NSMakeRange(0, (self as NSString).length))
        return newStr.componentsSeparatedByString(" ")
    }
    
}
