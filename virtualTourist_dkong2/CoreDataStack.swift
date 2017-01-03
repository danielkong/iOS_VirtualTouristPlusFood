//
//  CoreDataStack.swift
//  virtualTourist_dkong
//
//  Created by Daniel Kong on 11/20/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//
// Note: In this file, most logic copy from CoolNotes

import Foundation
import CoreData

class CoreDataStack {
    
    class func sharedInstance() -> CoreDataStack {
        struct Static {
            static let instance = CoreDataStack.init(modelName: "Data")
        }
        return Static.instance!
    }
    
    private let model: NSManagedObjectModel
    internal let coordinator: NSPersistentStoreCoordinator
    private let modelURL: NSURL
    internal let dbURL: NSURL
    let context: NSManagedObjectContext

    init?(modelName: String) {
        guard let modelURL = NSBundle.mainBundle().URLForResource(modelName, withExtension: "momd") else {
            print("Unable found \(modelName) in the main bundle")
            return nil
        }
        self.modelURL = modelURL
        
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else {
            print("unable to create a model with url \(modelURL)")
            return nil
        }
        self.model = model

        context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        context.persistentStoreCoordinator = coordinator
        let fm = NSFileManager.defaultManager()
        guard let docUrl = fm.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first else {
            print("Unable to get the documents folder")
            return nil
        }
        self.dbURL = docUrl.URLByAppendingPathComponent("model.sqlite")!
        do {
            try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: [NSInferMappingModelAutomaticallyOption: true, NSMigratePersistentStoresAutomaticallyOption: true])
        } catch {
            print("unable to add store at \(dbURL)")
        }
    }
        
    func addStoreCoordinator(storeType: String, configuration: String?, storeURL: NSURL, options : [NSObject:AnyObject]?) throws {
        try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: dbURL, options: nil)
    }
}

internal extension CoreDataStack  {
        
    func dropAllData() throws {
        try coordinator.destroyPersistentStoreAtURL(dbURL, withType: NSSQLiteStoreType, options: nil)
        try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
    }
}

extension CoreDataStack {
    
    func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    func autoSave(delayInSeconds : Int) {
        if delayInSeconds > 0 {
            do {
                try saveContext()
            } catch {
                print("Could not save during autosaving")
            }
            let delayInNanoSeconds = UInt64(delayInSeconds) * NSEC_PER_SEC
            let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
            let time = Double(dispatchTime) + Double(Int64(delayInNanoSeconds)) / Double(NSEC_PER_SEC)
            dispatch_after(UInt64(time), dispatch_get_main_queue()) {
                self.autoSave(delayInSeconds)
            }
        }
    }
}

internal extension NSManagedObjectContext {
    func saveToManagedObjectContext() {
        if self.hasChanges {
            try! save()
        }
    }
}
