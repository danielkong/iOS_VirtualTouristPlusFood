//
//  Pin+CoreDataClass.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 12/4/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Pin)
public class Pin: NSManagedObject, MKAnnotation {
    
    public var coordinate: CLLocationCoordinate2D {
        set {
            latitude = Double(newValue.latitude)
            longitude = Double(newValue.longitude)
        }
        
        get {
            return CLLocationCoordinate2D(latitude: Double(latitude), longitude: Double(longitude))
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) {
            super.init(entity: entity, insertIntoManagedObjectContext: context)
            self.latitude = Double(latitude)
            self.longitude = Double(longitude)
            self.flickr = Flickr(nextPage: 1, totalPages: 1, context: context)

        } else {
            fatalError("Unable to find Entity name with Pin!")
        }
    }
    
    func deleteExistingPhotos(context: NSManagedObjectContext, handler: (error: String?) -> Void) {
        let request = NSFetchRequest(entityName: "Photo")
        request.predicate = NSPredicate(format: "pin == %@", self)
        
        do {
            let photos = try context.executeFetchRequest(request) as! [Photo]
            _ = photos.map({ context.deleteObject($0) })
        } catch {
            fatalError("Get wrong fetch results!")
        }
        
        handler(error: nil)
    }
    
    func deleteExistingBusinesses(context: NSManagedObjectContext, handler: (error: String?) -> Void) {
        let request = NSFetchRequest(entityName: "Business")
        request.predicate = NSPredicate(format: "pin == %@", self)
        
        do {
            let photos = try context.executeFetchRequest(request) as! [Business]
            _ = photos.map({ context.deleteObject($0) })
        } catch {
            fatalError("Get wrong fetch results!")
        }
        
        handler(error: nil)
    }
}
