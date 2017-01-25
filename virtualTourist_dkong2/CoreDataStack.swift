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
    
    fileprivate let model: NSManagedObjectModel
    internal let coordinator: NSPersistentStoreCoordinator
    fileprivate let modelURL: URL
    internal let dbURL: URL
    let context: NSManagedObjectContext

    init?(modelName: String) {
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            print("Unable found \(modelName) in the main bundle")
            return nil
        }
        self.modelURL = modelURL
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            print("unable to create a model with url \(modelURL)")
            return nil
        }
        self.model = model

        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        context.persistentStoreCoordinator = coordinator
        let fm = FileManager.default
        guard let docUrl = fm.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("Unable to get the documents folder")
            return nil
        }
        self.dbURL = docUrl.appendingPathComponent("model.sqlite")
        do {
            try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: [NSInferMappingModelAutomaticallyOption: true, NSMigratePersistentStoresAutomaticallyOption: true])
        } catch {
            print("unable to add store at \(dbURL)")
        }
    }
        
    func addStoreCoordinator(_ storeType: String, configuration: String?, storeURL: URL, options : [AnyHashable: Any]?) throws {
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dbURL, options: nil)
    }
}

internal extension CoreDataStack  {
        
    func dropAllData() throws {
        try coordinator.destroyPersistentStore(at: dbURL, ofType: NSSQLiteStoreType, options: nil)
        try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)
    }
}

extension CoreDataStack {
    
    func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    func autoSave(_ delayInSeconds : Int) {
        if delayInSeconds > 0 {
            do {
                try saveContext()
            } catch {
                print("Could not save during autosaving")
            }
            let delayInNanoSeconds = UInt64(delayInSeconds) * NSEC_PER_SEC
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC) + Double(delayInNanoSeconds)/Double(NSEC_PER_SEC)) {
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
