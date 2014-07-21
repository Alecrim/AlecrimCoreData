//
//  NSManagedObject+Extensions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2014-06-24.
//  Copyright (c) 2014 Alecrim. All rights reserved.
//

import Foundation
import CoreData

// #pragma mark - Entity Information

public extension NSManagedObject {
    
    // TODO: change to class var when possible?
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

    public func inContext(otherContext: NSManagedObjectContext) -> Self? {
        if self.managedObjectContext == otherContext {
            return self
        }
        
        var error: NSError? = nil
        if self.objectID.temporaryID {
            let success = self.managedObjectContext.obtainPermanentIDsForObjects([ self ], error: &error)
            if !success {
                return nil
            }
        }
        
        let inContext = otherContext.existingObjectWithID(self.objectID, error: &error)
        
        return reinterpretCast(inContext)
    }
    
    
    // https://devforums.apple.com/message/1003791#1003791
//    class func createEntity(managedObjectContext: NSManagedObjectContext) -> Self {
//        let entity = self.entity(managedObjectContext.persistentStoreCoordinator.managedObjectModel)
//        return reinterpretCast(NSManagedObject(entity: entity, insertIntoManagedObjectContext: managedObjectContext))
//    }
//    
//    class func entity(model: NSManagedObjectModel) -> NSEntityDescription {
//        let className = self.description()
//        
//        let entities = (model.entities as [NSEntityDescription]).filter { entity in
//            // Note: I wasn't able to test this with Module.ClassName syntax, so
//            // you might have to round-trip managedObjectClassName through
//            // NSClassFromString()?.description() to get a class name you can compare.
//            return entity.managedObjectClassName == className
//        }
//        
//        assert(entities.count == 1, "Class cannot be unambiguously matched to a single entity")
//        
//        return entities[0]
//    }
    
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
            if String(character).toInt() {
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
                if String(character).toInt() {
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
