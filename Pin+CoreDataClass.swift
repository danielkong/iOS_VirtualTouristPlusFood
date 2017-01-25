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
open class Pin: NSManagedObject, MKAnnotation {
    
    open var coordinate: CLLocationCoordinate2D {
        set {
            latitude = Double(newValue.latitude)
            longitude = Double(newValue.longitude)
        }
        
        get {
            return CLLocationCoordinate2D(latitude: Double(latitude), longitude: Double(longitude))
        }
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            super.init(entity: entity, insertInto: context)
            self.latitude = Double(latitude)
            self.longitude = Double(longitude)
            self.flickr = Flickr(nextPage: 1, totalPages: 1, context: context)

        } else {
            fatalError("Unable to find Entity name with Pin!")
        }
    }
    
    func deleteExistingPhotos(_ context: NSManagedObjectContext, handler: (_ error: String?) -> Void) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        request.predicate = NSPredicate(format: "pin == %@", self)
        
        do {
            let photos = try context.fetch(request) as! [Photo]
            _ = photos.map({ context.delete($0) })
        } catch {
            fatalError("Get wrong fetch results!")
        }
        
        handler(nil)
    }
    
    func deleteExistingBusinesses(_ context: NSManagedObjectContext, handler: (_ error: String?) -> Void) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Business")
        request.predicate = NSPredicate(format: "pin == %@", self)
        
        do {
            let photos = try context.fetch(request) as! [Business]
            _ = photos.map({ context.delete($0) })
        } catch {
            fatalError("Get wrong fetch results!")
        }
        
        handler(nil)
    }
}
