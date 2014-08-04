//
//  NSManagedObject+Extensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-24.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject {
    
    public func inDataModel(dataModel: CoreDataModel) -> Self? {
        return self.inContext(dataModel as NSManagedObjectContext)
    }
    
    private func inContext(otherContext: NSManagedObjectContext) -> Self? {
        if self.managedObjectContext == otherContext {
            return self
        }
        
        var error: NSError? = nil
        if self.objectID.temporaryID {
            let success = self.managedObjectContext.obtainPermanentIDsForObjects([self], error: &error)
            if !success {
                return nil
            }
        }
        
        let objectInContext = otherContext.existingObjectWithID(self.objectID, error: &error)
        
        return unsafeBitCast(objectInContext, self.dynamicType)
    }
    
}

extension NSManagedObject {
    
    internal class func getEntityName() -> String {
        let className: NSString = ___nameOfClass(self)
        let range = className.rangeOfString("Entity")
        
        if range.location == NSNotFound || range.location == 0 {
            return className;
        }
        else {
            return className.substringToIndex(range.location)
        }
    }

}

// from: https://github.com/indieSoftware/INSwift
private func ___nameOfClass(classType: AnyClass) -> String {
    let stringOfClassType: String = NSStringFromClass(classType)
    
    // parse the returned string
    let swiftClassPrefix = "_TtC"
    if stringOfClassType.hasPrefix(swiftClassPrefix) {
        // convert the string into an array for easyer access to the characters in it
        let characters = Array(stringOfClassType)
        var ciphersForModule = String()
        // parse the ciphers for the module name's length
        var index = countElements(swiftClassPrefix)
        while index < characters.count {
            let character = characters[index++]
            if String(character).toInt() != nil {
                // character is a cipher
                ciphersForModule += character
            } else {
                // no cipher, module name begins
                break
            }
        }
        // create a number from the ciphers
        if let numberOfCharactersOfModuleName = ciphersForModule.toInt() {
            // ciphers contains a valid number, so skip the module name minus 1 because we already read one character f the module name
            index += numberOfCharactersOfModuleName - 1
            var ciphersForClass = String()
            while index < characters.count {
                let character = characters[index++]
                if (String(character).toInt() != nil) {
                    // character is a cipher
                    ciphersForClass += character
                } else {
                    // no cipher, class name begins
                    break
                }
            }
            // create a number from the ciphers
            if let numberOfCharactersOfClassName = ciphersForClass.toInt() {
                // number parsed, but make sure it does not exceeds the string's length
                if numberOfCharactersOfClassName > 0 && index - 1 + numberOfCharactersOfClassName <= characters.count {
                    // valid number, get the substring which should be the classes' name
                    let range = NSRange(location: index - 1, length: numberOfCharactersOfClassName)
                    let nameOfClass = (stringOfClassType as NSString).substringWithRange(range)
                    return nameOfClass
                }
            }
        }
    }
    
    // string couldn't be parsed so just return the returned string
    return stringOfClassType
}
