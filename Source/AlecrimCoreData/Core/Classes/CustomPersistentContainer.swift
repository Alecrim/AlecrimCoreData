//
//  CustomPersistentContainer.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2016-10-13.
//  Copyright © 2016 Alecrim. All rights reserved.
//

//
//  Portions of this Software may utilize modified versions of the following
//  open source copyrighted material, the use of which is hereby acknowledged:
//
//  INSPersistentContainer [https://github.com/inspace-io/INSPersistentContainer]
//  Created by Michal Zaborowski on 24.06.2016.
//  Copyright © 2016 Inspace Labs Sp z o. o. Spółka Komandytowa. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//


import Foundation
import CoreData

// MARK: -

private let _defaultDirectoryURL: URL = {
    #if os(tvOS)
        let searchPathDirectory = FileManager.SearchPathDirectory.cachesDirectory
    #else
        let searchPathDirectory = FileManager.SearchPathDirectory.applicationSupportDirectory
    #endif
    
    var appDirectory: URL
    
    do {
        appDirectory = try FileManager.default.url(for: searchPathDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }
    catch {
        fatalError("Found no possible URLs for directory.")
    }
    
    #if os(macOS)
        guard let suffix = Bundle.main.infoDictionary?[kCFBundleExecutableKey as String] as? String ?? Bundle.main.executableURL?.lastPathComponent else {
            fatalError("Could not get application name information from bundle \(Bundle.main).")
        }
        
        appDirectory.appendPathComponent(suffix)
    #endif
    
    do {
        try FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
    }
    catch CocoaError.fileWriteFileExists {
        fatalError("File \(appDirectory) already exists and is not a directory.")
    }
    catch {
        fatalError("Failed to create directory \(appDirectory): \(error).")
    }
    
    return appDirectory
}()

// MARK: -

internal class CustomPersistentContainer: NSObject, UnderlyingPersistentContainer {

    // MARK: -
    
    internal class func defaultDirectoryURL() -> URL { return _defaultDirectoryURL }
    
    // MARK: -
    
    private let contextType: NSManagedObjectContext.Type
    
    internal let name: String
    internal let viewContext: NSManagedObjectContext
    internal var managedObjectModel: NSManagedObjectModel { return self.persistentStoreCoordinator.managedObjectModel }
    internal let persistentStoreCoordinator: NSPersistentStoreCoordinator
    internal var alc_persistentStoreDescriptions: [PersistentStoreDescription]

    // MARK: -
    
    internal required init(name: String, managedObjectModel model: NSManagedObjectModel, contextType: NSManagedObjectContext.Type) {
        self.contextType = contextType
        
        self.name = name
        self.persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        self.viewContext = self.contextType.init(concurrencyType: .mainQueueConcurrencyType)
        self.viewContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        
        self.alc_persistentStoreDescriptions = [CustomPersistentStoreDescription(url: type(of: self).defaultDirectoryURL().appendingPathComponent("\(name).sqlite"))]
    }
    
    // MARK: -
    
    internal func newBackgroundContext() -> NSManagedObjectContext {
        let context = self.contextType.init(concurrencyType: .privateQueueConcurrencyType)
        
        if let parentContext = self.viewContext.parent {
            context.parent = parentContext
        }
        else {
            context.persistentStoreCoordinator = self.persistentStoreCoordinator
        }
        
        return context
    }

    // MARK: -
    
    internal func alc_loadPersistentStores(completionHandler block: @escaping (PersistentStoreDescription, Error?) -> Void) {
        self.alc_persistentStoreDescriptions.forEach {
            self.persistentStoreCoordinator.alc_addPersistentStore(with: $0, completionHandler: block)
        }
    }
    
    internal func configureDefaults(for context: NSManagedObjectContext) {
        context.alc_automaticallyMergesChangesFromParent = true
        context.alc_automaticallyObtainPermanentIDsForInsertedObjects = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
}

// MARK: -

extension NSPersistentStoreCoordinator {

    fileprivate func alc_addPersistentStore(with storeDescription: PersistentStoreDescription, completionHandler block: @escaping (PersistentStoreDescription, Error?) -> Void) {
        if storeDescription.shouldAddStoreAsynchronously {
            DispatchQueue.global(qos: .background).async {
                do {
                    try self.addPersistentStore(ofType: storeDescription.type, configurationName: storeDescription.configuration, at: storeDescription.url, options: storeDescription.options)
                    block(storeDescription, nil)
                }
                catch {
                    block(storeDescription, error)
                }
            }
        }
        else {
            do {
                try self.addPersistentStore(ofType: storeDescription.type, configurationName: storeDescription.configuration, at: storeDescription.url, options: storeDescription.options)
                block(storeDescription, nil)
            }
            catch {
                block(storeDescription, error)
            }
        }
    }
    
}

// MARK: -

extension NSManagedObjectContext {
    
    private struct AssociatedKeys {
        static var mergesChangesFromParent: String = "alc_automaticallyMergesChangesFromParent"
        static var obtainPermamentIDsForInsertedObjects: String = "alc_automaticallyObtainPermanentIDsForInsertedObjects"
        static var notificationQueue: String = "alc_notificationQueue"
    }
    
    private var notificationQueue: DispatchQueue {
        guard let notificationQueue = objc_getAssociatedObject(self, &AssociatedKeys.notificationQueue) as? DispatchQueue else {
            let queue = DispatchQueue(label: "com.alecrim.AlecrimCoreData.ManagedObjectContext.NotificationQueue." + UUID().uuidString)
            objc_setAssociatedObject(self, &AssociatedKeys.obtainPermamentIDsForInsertedObjects, queue, .OBJC_ASSOCIATION_RETAIN)
            
            return queue
        }
        
        return notificationQueue
    }
    
    private var _alc_automaticallyObtainPermanentIDsForInsertedObjects: Bool {
        return objc_getAssociatedObject(self, &AssociatedKeys.obtainPermamentIDsForInsertedObjects) as? Bool ?? false
    }
    
    internal var alc_automaticallyObtainPermanentIDsForInsertedObjects: Bool {
        set {
            self.notificationQueue.sync {
                if newValue != self._alc_automaticallyObtainPermanentIDsForInsertedObjects {
                    objc_setAssociatedObject(self, &AssociatedKeys.obtainPermamentIDsForInsertedObjects, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    
                    if newValue {
                        NotificationCenter.default.addObserver(self, selector: #selector(NSManagedObjectContext.alc_automaticallyObtainPermanentIDsForInsertedObjectsFromWillSaveNotification(_:)), name: NSNotification.Name.NSManagedObjectContextWillSave, object: self)
                    }
                    else {
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextWillSave, object: self)
                    }
                }
            }
        }
        get {
            var value = false
            
            self.notificationQueue.sync {
                value = self._alc_automaticallyObtainPermanentIDsForInsertedObjects
            }
            
            return value
        }
    }
    
    private var _alc_automaticallyMergesChangesFromParent: Bool {
        return objc_getAssociatedObject(self, &AssociatedKeys.mergesChangesFromParent) as? Bool ?? false
    }
    
    internal var alc_automaticallyMergesChangesFromParent: Bool {
        set {
            if self.concurrencyType == NSManagedObjectContextConcurrencyType(rawValue: 0) /* .ConfinementConcurrencyType */ {
                fatalError("Automatic merging is not supported by contexts using NSConfinementConcurrencyType")
            }
            
            if self.parent == nil && self.persistentStoreCoordinator == nil {
                fatalError("Cannot enable automatic merging for a context without a parent, set a parent context or persistent store coordinator first.")
            }
            
            self.notificationQueue.sync {
                if newValue != self._alc_automaticallyMergesChangesFromParent {
                    objc_setAssociatedObject(self, &AssociatedKeys.mergesChangesFromParent, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    
                    if newValue {
                        NotificationCenter.default.addObserver(self, selector: #selector(NSManagedObjectContext.alc_automaticallyMergeChangesFromContextDidSaveNotification(_:)), name: NSNotification.Name.NSManagedObjectContextDidSave, object: self.parent)
                    }
                    else {
                        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSManagedObjectContextDidSave, object: self.parent)
                    }
                }
            }
        }
        get {
            if self.concurrencyType == NSManagedObjectContextConcurrencyType(rawValue: 0) /* .ConfinementConcurrencyType */ {
                return false
            }
            
            var value = false
            
            self.notificationQueue.sync {
                value = self._alc_automaticallyMergesChangesFromParent
            }
            
            return value
        }
    }
    
    @objc private func alc_automaticallyMergeChangesFromContextDidSaveNotification(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext, let persistentStoreCoordinator = persistentStoreCoordinator, let contextCoordinator = context.persistentStoreCoordinator , persistentStoreCoordinator == contextCoordinator else {
            return
        }
        
        let isRootContext = context.parent == nil
        let isParentContext = parent == context
        
        guard (isRootContext || isParentContext) && context != self else {
            return
        }
        
        self.perform {
            // WORKAROUND FOR: http://stackoverflow.com/questions/3923826/nsfetchedresultscontroller-with-predicate-ignores-changes-merged-from-different/3927811#3927811
            if let updatedObjects = (notification as NSNotification).userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject>, !updatedObjects.isEmpty {
                updatedObjects.forEach {
                    self.object(with: $0.objectID).willAccessValue(forKey: nil) // ensures that a fault has been fired
                }
            }
            
            self.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    @objc private func alc_automaticallyObtainPermanentIDsForInsertedObjectsFromWillSaveNotification(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext, context.insertedObjects.count > 0 else {
            return
        }
        
        context.perform {
            _ = try? context.obtainPermanentIDs(for: Array(context.insertedObjects))
        }
    }
}

