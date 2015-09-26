//
//  ALCFetchedResultsController.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-06-08.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

//
//  Portions of this Software may utilize modified versions of the following
//  open source copyrighted material, the use of which is hereby acknowledged:
//
//  BBFetchedResultsController [https://github.com/brblakley/BBFetchedResultsController]
//  Copyright (C) 2013 Ben Blakely. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//  of the Software, and to permit persons to whom the Software is furnished
//  to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//


#if os(OSX)

import Foundation
import CoreData

// MARK: -

public typealias NSFetchedResultsChangeType = ALCFetchedResultsChangeType
public typealias NSFetchedResultsSectionInfo = ALCFetchedResultsSectionInfo
public typealias NSFetchedResultsControllerDelegate = ALCFetchedResultsControllerDelegate
public typealias NSFetchedResultsController = ALCFetchedResultsController


// MARK: -

@objc public enum ALCFetchedResultsChangeType : UInt {
    case Insert
    case Delete
    case Move
    case Update
}

// MARK: -

@objc public protocol ALCFetchedResultsSectionInfo {
    var name: String { get }
    var indexTitle: String { get }
    var numberOfObjects: Int { get }
    var objects: [NSManagedObject]? { get }
}

// MARK: -

@objc public protocol ALCFetchedResultsControllerDelegate: class {
    optional func controller(controller: ALCFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: ALCFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    optional func controller(controller: ALCFetchedResultsController, didChangeSection sectionInfo: ALCFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: ALCFetchedResultsChangeType)
    optional func controllerWillChangeContent(controller: ALCFetchedResultsController)
    optional func controllerDidChangeContent(controller: ALCFetchedResultsController)
    optional func controller(controller: ALCFetchedResultsController, sectionIndexTitleForSectionName sectionName: String) -> String?
}

// MARK: -

public class ALCFetchedResultsController: NSObject {
    
    public let observedManagedObjectContext: NSManagedObjectContext

    
    // MARK: -
    
    public let fetchRequest: NSFetchRequest
    public let managedObjectContext: NSManagedObjectContext
    public let sectionNameKeyPath: String?
    public let cacheName: String? // never used in this implementation
    
    // MARK: -
    
    public weak var delegate: ALCFetchedResultsControllerDelegate?

    // MARK: -

    public class func deleteCacheWithName(name: String?) {
        // do nothing in this implementation
    }

    // MARK: -

    public private(set) var sections: [ALCFetchedResultsSectionInfo]?
    public private(set) var fetchedObjects: [NSManagedObject]?

    private var _sectionIndexTitles: [String]? = nil
    public var sectionIndexTitles: [String] {
        if self._sectionIndexTitles == nil {
            if let sections = self.sections as? [ALCSectionInfo] {
                self._sectionIndexTitles = [String]()
                for section in sections {
                    let sectionIndexTitle = (self.delegate?.controller?(self, sectionIndexTitleForSectionName: section.name) ?? self.sectionIndexTitleForSectionName(section.name)) ?? ""
                    self._sectionIndexTitles!.append(sectionIndexTitle)
                }
            }
        }
        
        return self._sectionIndexTitles ?? [String]()
    }
    
    // MARK: -
    
    public init(fetchRequest: NSFetchRequest, managedObjectContext context: NSManagedObjectContext, sectionNameKeyPath: String?, cacheName name: String?) {
        //
        self.fetchRequest = fetchRequest
        self.managedObjectContext = context
        self.sectionNameKeyPath = sectionNameKeyPath
        self.cacheName = name
        
        //
        var observedManagedObjectContext = managedObjectContext
        while observedManagedObjectContext.parentContext != nil {
            observedManagedObjectContext = observedManagedObjectContext.parentContext!
        }
        
        self.observedManagedObjectContext = observedManagedObjectContext
        
        //
        super.init()
        
        //
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleContextChangesWithNotification:"), name: NSManagedObjectContextDidSaveNotification, object: self.observedManagedObjectContext)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: self.observedManagedObjectContext)
    }
    
    // MARK: -

    public func performFetch() throws {
        var error: ErrorType?
        
        self.managedObjectContext.performBlockAndWait {
            do {
                try self.calculateSections()
            }
            catch let innerError {
                error = innerError
            }
        }
        
        if let error = error {
            throw error
        }
    }
    
    public func objectAtIndexPath(indexPath: NSIndexPath) -> NSManagedObject {
        if let section = self.sections?[indexPath.section] as? ALCSectionInfo {
            if let fetchedObjects = self.fetchedObjects {
                return fetchedObjects[section.range.location + indexPath.item]
            }
        }
        
        AlecrimCoreDataError.fatalError("Object not found and we cannot return nil.")
    }

    public func indexPathForObject(object: NSManagedObject) -> NSIndexPath? {
        var indexPath: NSIndexPath? = nil
        
        if let sections = self.sections as? [ALCSectionInfo], fetchedObjects = self.fetchedObjects {
            let index = (fetchedObjects as NSArray).indexOfObject(object)
            if index != NSNotFound {
                var sectionIndex = 0
                for section in sections {
                    if NSLocationInRange(index, section.range) {
                        let itemIndex = index - section.range.location
                        indexPath = NSIndexPath(forItem: itemIndex, inSection: sectionIndex)
                        break
                    }
                    
                    sectionIndex++
                }
            }
        }
        
        return indexPath
    }
    
    // MARK: -
    
    public func sectionIndexTitleForSectionName(sectionName: String) -> String? {
        if let d = self.delegate, let o = d as? NSObject where o.respondsToSelector(Selector("controller:sectionIndexTitleForSectionName:")) {
            return d.controller!(self, sectionIndexTitleForSectionName: sectionName)
        }
        else {
            let string = sectionName as NSString
            if string.length > 0 {
                return string.substringToIndex(1).capitalizedString
            }
        }
        
        return nil
    }
    
    public func sectionForSectionIndexTitle(title: String, atIndex sectionIndex: Int) -> Int {
        return sectionIndex
    }
    
}

// MARK: -

extension ALCFetchedResultsController {
    
    @objc private func handleContextChangesWithNotification(notification: NSNotification) {
        // we need a `performFetch:` call first
        guard self.fetchedObjects != nil else { return }
        
        //
        guard
            notification.object is NSManagedObjectContext,
            let userInfo = notification.userInfo,
            let entityName = self.fetchRequest.entityName
        else {
            return
        }
        
        //
        let contextInsertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
        let contextUpdatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
        let contextDeletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? Set<NSManagedObject>()
        
        self.managedObjectContext.performBlock {
            var insertedObjects = contextInsertedObjects.filter({ $0.entity.name == entityName }).map({ try! $0.inContext(self.managedObjectContext) })
            let updatedObjects = contextUpdatedObjects.filter({ $0.entity.name == entityName }).map({ try! $0.inContext(self.managedObjectContext) })
            var deletedObjects = contextDeletedObjects.filter({ $0.entity.name == entityName }).map({ try! $0.inContext(self.managedObjectContext) })
            
            if let predicate = self.fetchRequest.predicate {
                insertedObjects = (insertedObjects as NSArray).filteredArrayUsingPredicate(predicate) as! [NSManagedObject]
                
                // updatedObjects is a special case handled in handleCallbacksWithDelegate
                
                deletedObjects = (deletedObjects as NSArray).filteredArrayUsingPredicate(predicate) as! [NSManagedObject]
            }
            
            if insertedObjects.count > 0 || updatedObjects.count > 0 || deletedObjects.count > 0 {
                let (oldSections, oldFetchedObjects, newSections, newFetchedObjects) = try! self.calculateSections()
                if self.delegate != nil && oldSections != nil && oldFetchedObjects != nil && newSections != nil && newFetchedObjects != nil {
                    self.handleCallbacksWithDelegate(self.delegate!, oldSections: oldSections as! [ALCSectionInfo], oldFetchedObjects: oldFetchedObjects!, newSections: self.sections as! [ALCSectionInfo], newFetchedObjects: self.fetchedObjects!, insertedObjects: insertedObjects, updatedObjects: updatedObjects, deletedObjects: deletedObjects)
                }
            }
        }
    }
    
}

// MARK: -

extension ALCFetchedResultsController {
    
    private func calculateSections() throws -> (oldSections: [ALCFetchedResultsSectionInfo]?, oldFetchedObjects: [NSManagedObject]?, newSections: [ALCFetchedResultsSectionInfo]?, newFetchedObjects: [NSManagedObject]?) {
        let oldSections = self.sections
        let oldFetchedObjects = self.fetchedObjects
        
        //
        self.sections = nil
        self.fetchedObjects = nil
        self._sectionIndexTitles = nil
        
        //
        let fetchRequestObjects = try self.managedObjectContext.executeFetchRequest(self.fetchRequest)
        if let fetchRequestManagedObjects = fetchRequestObjects as? [NSManagedObject] {
            self.fetchedObjects = fetchRequestManagedObjects
        }
        else {
            throw AlecrimCoreDataError.UnexpectedValue(value: fetchRequestObjects)
        }

        //
        var results: [AnyObject]? = nil
        
        if let sectionNameKeyPath = self.sectionNameKeyPath {
            //
            var calculatedSections = [ALCSectionInfo]()
            
            //
            if self.fetchRequest.entity!.properties.map({ $0.name }).indexOf(sectionNameKeyPath.componentsSeparatedByString(".").first!) != nil {
                let countFetchRequest = self.fetchRequest.copy() as! NSFetchRequest
                countFetchRequest.fetchOffset = 0
                countFetchRequest.fetchLimit = 0
                countFetchRequest.fetchBatchSize = 0
                
                countFetchRequest.propertiesToFetch = nil
                countFetchRequest.resultType = .DictionaryResultType
                countFetchRequest.relationshipKeyPathsForPrefetching = nil
                
                let countDescription = NSExpressionDescription()
                countDescription.name = "count"
                countDescription.expression = NSExpression(forFunction: "count:", arguments: [NSExpression.expressionForEvaluatedObject()])
                countDescription.expressionResultType = .Integer32AttributeType
                
                countFetchRequest.propertiesToFetch = [self.sectionNameKeyPath!, countDescription]
                countFetchRequest.propertiesToGroupBy = [self.sectionNameKeyPath!]
                
                results = try self.managedObjectContext.executeFetchRequest(countFetchRequest)
            }
            else {
                // sectionNameKeyPath is a transient property, count manually
                let countedSet = NSCountedSet(capacity: 0)
                let array = (self.fetchedObjects! as NSArray).valueForKey(sectionNameKeyPath) as! [AnyObject]
                countedSet.addObjectsFromArray(array)
                
                let dicts = NSMutableArray()
                for object in countedSet {
                    let count = countedSet.countForObject(object)
                    let dict = NSDictionary(objects: [object, count], forKeys: [sectionNameKeyPath, "count"])
                    dicts.addObject(dict)
                }

                // we have to assume that the first sort descriptor exists and that it defines the order
                let ascending = self.fetchRequest.sortDescriptors!.first!.ascending
                let sortedDicts = dicts.sortedArrayUsingComparator { obj1, obj2 in
                    let dict1 = obj1 as! NSDictionary
                    let dict2 = obj2 as! NSDictionary
                    
                    let sectionIdentifier1 = dict1[sectionNameKeyPath] as! String
                    let sectionIdentifier2 = dict2[sectionNameKeyPath] as! String
                    
                    if ascending {
                        return sectionIdentifier1.compare(sectionIdentifier2)
                    }
                    else {
                        return sectionIdentifier2.compare(sectionIdentifier1)
                    }
                }
                
                //
                results = sortedDicts
            }

            //
            var fetchedObjectsCount = 0
            var offset = self.fetchRequest.fetchOffset
            let limit = self.fetchRequest.fetchLimit
            
            if let dicts = results as? [NSDictionary] {
                for dict in dicts {
                    if let _count = (dict["count"] as? NSNumber)?.intValue {
                        var count = Int(_count)
                        
                        if offset >= count {
                            offset -= count
                            continue
                        }
                        
                        let _value: AnyObject? = dict[sectionNameKeyPath]
                        
                        //
                        count -= offset
                        if limit > 0 {
                            count = min(count, limit - fetchedObjectsCount)
                        }
                        
                        //
                        let sectionName: String
                        if let string = _value as? String {
                            sectionName = string
                        }
                        else if let object = _value as? NSObject {
                            sectionName = object.description
                        }
                        else {
                            sectionName = "\(_value)"
                        }
                        
                        let sectionIndexTitle = (self.delegate?.controller?(self, sectionIndexTitleForSectionName: sectionName) ?? self.sectionIndexTitleForSectionName(sectionName)) ?? ""
                        
                        let section = ALCSectionInfo(fetchedResultsController: self, range: NSMakeRange(fetchedObjectsCount, count), name: sectionName, indexTitle: sectionIndexTitle)
                        
                        calculatedSections.append(section)
                        
                        //
                        fetchedObjectsCount += count
                        offset -= min(count, offset)
                        
                        if limit > 0 && fetchedObjectsCount == limit {
                            break
                        }
                    }
                }
            }
            
            //
            self.sections = calculatedSections
        }
        else {
            //
            let section = ALCSectionInfo(fetchedResultsController: self, range: NSMakeRange(0, self.fetchedObjects?.count ?? 0), name: "", indexTitle: "")
            self.sections = [section]
        }
        
        
        //
        return (oldSections, oldFetchedObjects, self.sections, self.fetchedObjects)
    }
    
    private func handleCallbacksWithDelegate(delegate: ALCFetchedResultsControllerDelegate, oldSections: [ALCSectionInfo], oldFetchedObjects: [NSManagedObject], newSections: [ALCSectionInfo], newFetchedObjects: [NSManagedObject], var insertedObjects: [NSManagedObject], var updatedObjects: [NSManagedObject], var deletedObjects: [NSManagedObject]) {
        //
        var controllerWillChangeContentCalled = false

        //
        func callControllerWillChangeContentIfNeeded() {
            if !controllerWillChangeContentCalled {
                controllerWillChangeContentCalled = true
                delegate.controllerWillChangeContent?(self)
            }
        }
        
        //
        var movedObjects = [NSManagedObject]()

        //
        for oldSectionIndex in oldSections.startIndex..<oldSections.endIndex {
            var foundNewSectionIndex: Int? = nil
            for newSectionIndex in newSections.startIndex..<newSections.endIndex {
                if newSections[newSectionIndex].name == oldSections[oldSectionIndex].name {
                    foundNewSectionIndex = newSectionIndex
                    break
                }
            }
            
            if foundNewSectionIndex == nil {
                callControllerWillChangeContentIfNeeded()
                delegate.controller?(self, didChangeSection: oldSections[oldSectionIndex], atIndex: oldSectionIndex, forChangeType: .Delete)
            }
        }
        
        //
        for newSectionIndex in newSections.startIndex..<newSections.endIndex {
            var foundOldSectionIndex: Int? = nil
            for oldSectionIndex in oldSections.startIndex..<oldSections.endIndex {
                if oldSections[oldSectionIndex].name == newSections[newSectionIndex].name {
                    foundOldSectionIndex = oldSectionIndex
                    break
                }
            }
            
            if foundOldSectionIndex == nil {
                callControllerWillChangeContentIfNeeded()
                delegate.controller?(self, didChangeSection: newSections[newSectionIndex], atIndex: newSectionIndex, forChangeType: .Insert)
            }
        }
        
        //
        let updatedObjectsCopy = updatedObjects
        for updatedObject in updatedObjectsCopy {
            var oldIndexPath: NSIndexPath? = nil
            var newIndexPath: NSIndexPath? = nil
            
            //
            let oldIndex = (oldFetchedObjects as NSArray).indexOfObject(updatedObject)
            if oldIndex != NSNotFound {
                for oldSectionIndex in oldSections.startIndex..<oldSections.endIndex {
                    let oldSection = oldSections[oldSectionIndex]
                    if NSLocationInRange(oldIndex, oldSection.range) {
                        let oldItemIndex = oldIndex - oldSection.range.location
                        oldIndexPath = NSIndexPath(forItem: oldItemIndex, inSection: oldSectionIndex)
                        break
                    }
                }
            }
            
            //
            let newIndex = (newFetchedObjects as NSArray).indexOfObject(updatedObject)
            if newIndex != NSNotFound {
                for newSectionIndex in newSections.startIndex..<newSections.endIndex {
                    let newSection = newSections[newSectionIndex]
                    if NSLocationInRange(newIndex, newSection.range) {
                        let newItemIndex = newIndex - newSection.range.location
                        newIndexPath = NSIndexPath(forItem: newItemIndex, inSection: newSectionIndex)
                        break
                    }
                }
            }
            
            //
            if newIndexPath == nil && oldIndexPath == nil {
                if let index = updatedObjects.indexOf(updatedObject) {
                    updatedObjects.removeAtIndex(index)
                }
            }
            else if newIndexPath == nil && oldIndexPath != nil {
                if let index = updatedObjects.indexOf(updatedObject) {
                    updatedObjects.removeAtIndex(index)
                }
                
                deletedObjects.append(updatedObject)
            }
            else if newIndexPath != nil && oldIndexPath == nil {
                if let index = updatedObjects.indexOf(updatedObject) {
                    updatedObjects.removeAtIndex(index)
                }
                
                insertedObjects.append(updatedObject)
            }
            else { // newIndexPath != nil && oldIndexPath != nil
                var inSortDescriptors = false
                if let sortDescriptors = self.fetchRequest.sortDescriptors {
                    let changedValues = updatedObject.changedValues()
                    
                    for changedValueKey in changedValues.keys {
                        for sortDescriptor in sortDescriptors {
                            if let sortDescriptorKey = sortDescriptor.key {
                                if sortDescriptorKey == changedValueKey {
                                    inSortDescriptors = true
                                    break
                                }
                            }
                        }
                        if inSortDescriptors {
                            break
                        }
                    }
                }
                
                if inSortDescriptors {
                    if let index = updatedObjects.indexOf(updatedObject) {
                        updatedObjects.removeAtIndex(index)
                    }
                    
                    movedObjects.append(updatedObject)
                }
            }
        }
        
        //
        for deletedObject in deletedObjects {
            let oldIndex = (oldFetchedObjects as NSArray).indexOfObject(deletedObject)
            for oldSectionIndex in oldSections.startIndex..<oldSections.endIndex {
                let oldSection = oldSections[oldSectionIndex]
                if NSLocationInRange(oldIndex, oldSection.range) {
                    let oldItemIndex = oldIndex - oldSection.range.location
                    let oldIndexPath = NSIndexPath(forItem: oldItemIndex, inSection: oldSectionIndex)

                    callControllerWillChangeContentIfNeeded()
                    delegate.controller?(self, didChangeObject: deletedObject, atIndexPath: oldIndexPath, forChangeType: .Delete, newIndexPath: nil)
                    break
                }
            }
        }
        
        //
        for insertedObject in insertedObjects {
            let newIndex = (newFetchedObjects as NSArray).indexOfObject(insertedObject)
            for newSectionIndex in newSections.startIndex..<newSections.endIndex {
                let newSection = newSections[newSectionIndex]
                if NSLocationInRange(newIndex, newSection.range) {
                    let newItemIndex = newIndex - newSection.range.location
                    let newIndexPath = NSIndexPath(forItem: newItemIndex, inSection: newSectionIndex)

                    callControllerWillChangeContentIfNeeded()
                    delegate.controller?(self, didChangeObject: insertedObject, atIndexPath: nil, forChangeType: .Insert, newIndexPath: newIndexPath)
                    break
                }
            }
        }
        
        // On add and remove operations, only the added/removed object is reported.
        // It’s assumed that all objects that come after the affected object are also moved, but these moves are not reported.
        if insertedObjects.count == 0 && deletedObjects.count == 0 {
            // A move is reported when the changed attribute on the object is one of the sort descriptors used in the fetch request.
            // An update of the object is assumed in this case, but no separate update message is sent to the delegate.
            for movedObject in movedObjects {
                var oldIndexPath: NSIndexPath? = nil
                var newIndexPath: NSIndexPath? = nil
                
                //
                let oldIndex = (oldFetchedObjects as NSArray).indexOfObject(movedObject)
                if oldIndex != NSNotFound {
                    for oldSectionIndex in oldSections.startIndex..<oldSections.endIndex {
                        let oldSection = oldSections[oldSectionIndex]
                        if NSLocationInRange(oldIndex, oldSection.range) {
                            let oldItemIndex = oldIndex - oldSection.range.location
                            oldIndexPath = NSIndexPath(forItem: oldItemIndex, inSection: oldSectionIndex)
                            break
                        }
                    }
                }
                
                //
                let newIndex = (newFetchedObjects as NSArray).indexOfObject(movedObject)
                if newIndex != NSNotFound {
                    for newSectionIndex in newSections.startIndex..<newSections.endIndex {
                        let newSection = newSections[newSectionIndex]
                        if NSLocationInRange(newIndex, newSection.range) {
                            let newItemIndex = newIndex - newSection.range.location
                            newIndexPath = NSIndexPath(forItem: newItemIndex, inSection: newSectionIndex)
                            break
                        }
                    }
                }
                
                //
                callControllerWillChangeContentIfNeeded()
                delegate.controller?(self, didChangeObject: movedObject, atIndexPath: oldIndexPath, forChangeType: .Move, newIndexPath: newIndexPath)
            }
            
            // An update is reported when an object’s state changes, but the changed attributes aren’t part of the sort keys. 
            for updatedObject in updatedObjects {
                let newIndex = (newFetchedObjects as NSArray).indexOfObject(updatedObject)
                if newIndex != NSNotFound {
                    for newSectionIndex in newSections.startIndex..<newSections.endIndex {
                        let newSection = newSections[newSectionIndex]
                        if NSLocationInRange(newIndex, newSection.range) {
                            let newItemIndex = newIndex - newSection.range.location
                            let newIndexPath = NSIndexPath(forItem: newItemIndex, inSection: newSectionIndex)
                            
                            callControllerWillChangeContentIfNeeded()
                            delegate.controller?(self, didChangeObject: updatedObject, atIndexPath: newIndexPath, forChangeType: .Update, newIndexPath: newIndexPath)
                            break
                        }
                    }
                }
            }
        }
        
        //
        if controllerWillChangeContentCalled {
            delegate.controllerDidChangeContent?(self)
        }
    }
    
}

// MARK: -

private class ALCSectionInfo: NSObject, ALCFetchedResultsSectionInfo {
    
    private unowned let fetchedResultsController: ALCFetchedResultsController
    private let range: NSRange

    @objc private let name: String
    @objc private let indexTitle: String
    
    @objc private var numberOfObjects: Int {
        return self.range.length
    }
    
    @objc private var objects: [NSManagedObject]? {
        if let fetchedObjects = self.fetchedResultsController.fetchedObjects {
            return Array(fetchedObjects[self.range.location..<self.range.location + self.range.length])
        }
        
        return nil
    }
    
    private init(fetchedResultsController: ALCFetchedResultsController, range: NSRange, name: String, indexTitle: String) {
        self.fetchedResultsController = fetchedResultsController
        self.range = range
        
        self.name = name
        self.indexTitle = indexTitle
        
        super.init()
    }
    
}

// MARK: - NSIndexPath extensions

extension NSIndexPath {
    
    public convenience init(forItem item: Int, inSection section: Int) {
        let indexes = [section, item]
        self.init(indexes: indexes, length: 2)
    }
    
    public convenience init(forRow row: Int, inSection section: Int) {
        let indexes = [section, row]
        self.init(indexes: indexes, length: 2)
    }
    
    @objc(alecrimCoreDataSection)
    public var section: Int { return self.indexAtPosition(0) }
    
    @objc(alecrimCoreDataItem)
    public var item: Int { return self.indexAtPosition(1) }
    
    @objc(alecrimCoreDataRow)
    public var row: Int { return self.indexAtPosition(1) }
    
}
    
// MARK: - Table extensions
    
extension Table {

    public func toFetchedResultsController(sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> ALCFetchedResultsController {
        return ALCFetchedResultsController(fetchRequest: self.toFetchRequest(), managedObjectContext: self.dataContext, sectionNameKeyPath: sectionNameKeyPath, cacheName: cacheName)
    }

}

#endif
