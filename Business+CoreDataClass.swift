//
//  Business+CoreDataClass.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 12/13/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MapKit

@objc(Business)
public class Business: NSManagedObject, MKAnnotation {
    
    public var coordinate: CLLocationCoordinate2D {
        set {
            latitude = Double(newValue.latitude)
            longitude = Double(newValue.longitude)
        }
        
        get {
            return CLLocationCoordinate2D(latitude: Double(latitude), longitude: Double(longitude))
        }
    }
    
    lazy var filePath: String = {
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!.URLByAppendingPathComponent("image-\(self.id).jpg")!.path!
    } ()
    
    var task: NSURLSessionTask? = nil
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    
    init(id: String, url: String, pin: Pin, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Business", inManagedObjectContext: context) {
            super.init(entity: entity, insertIntoManagedObjectContext: context)
            
            self.id = id
            self.url = url
            self.pin = pin
            startLoadingImage(){ _ in }
        } else {
            fatalError("Unable to find Entity name with Business!")
        }
    }
    
    // create image url with pin
    init(dictionary: [String: AnyObject], pin: Pin, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Business", inManagedObjectContext: context) {
            super.init(entity: entity, insertIntoManagedObjectContext: context)
            
            self.name = dictionary["name"] as? String
            self.address = dictionary["address"] as? String
            self.imageURL = dictionary["image_url"] as? String
            startLoadingImage(){ _ in }
            self.categories = dictionary["categories"] as? String
            self.distance = dictionary["distance"] as? String
            if let coordinates: AnyObject = dictionary["coordinates"] {
                if coordinates is NSDictionary {
                    let coor = coordinates as! NSDictionary
                    self.latitude = (coor["latitude"] as? Double)!
                    self.longitude = (coor["longitude"] as? Double)!

                }
            }

            self.id = dictionary["id"] as? String
            self.phone = dictionary["phone"] as? String
            self.isClosed = (dictionary["is_closed"] as? Bool)!
            self.url = dictionary["url"] as? String
            self.rating = (dictionary["rating"] as? Double)!
            
            self.pin = pin
            
        } else {
            fatalError("Unable to find Entity name with Business!")
        }
    }
    
    func startLoadingImage(handler: (image : UIImage?, error: String?) -> Void) {
        if let urlString = imageURL, urlFormat = NSURL(string: urlString) {
            task = NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: urlFormat)) { (data, response, downloadError) in
                dispatch_sync(dispatch_get_main_queue(), {
                    guard downloadError == nil else {
                        return handler(image: nil, error: "Business download error")
                    }
                    
                    guard let data = data, let image = UIImage(data: data) else {
                        return handler(image: nil, error: "Business data not correct")
                    }
                    
                    self.imageData = UIImageJPEGRepresentation(image, 0.0)
                    return handler(image: image, error: nil)
                })
            }
            task?.resume()
        }
    }
}
