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
open class Business: NSManagedObject, MKAnnotation {
    
    open var coordinate: CLLocationCoordinate2D {
        set {
            latitude = Double(newValue.latitude)
            longitude = Double(newValue.longitude)
        }
        
        get {
            return CLLocationCoordinate2D(latitude: Double(latitude), longitude: Double(longitude))
        }
    }
    
    lazy var filePath: String = {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-\(self.id).jpg").path
    } ()
    
    var task: URLSessionTask? = nil
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    
    init(id: String, url: String, pin: Pin, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Business", in: context) {
            super.init(entity: entity, insertInto: context)
            
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
        if let entity = NSEntityDescription.entity(forEntityName: "Business", in: context) {
            super.init(entity: entity, insertInto: context)
            
            self.name = dictionary["name"] as? String
            self.address = dictionary["address"] as? String
            self.imageURL = dictionary["image_url"] as? String
            startLoadingImage(){ _ in }
            self.categories = dictionary["categories"] as? String
            self.distance = dictionary["distance"] as? String
            if let coordinates: AnyObject = dictionary["coordinates"] {
                if coordinates is NSDictionary {
                    let coor = coordinates as! NSDictionary
                    if let lati = coor["latitude"] as? Double, let long = coor["longitude"] as? Double {
                        self.latitude = lati
                        self.longitude = long
                    } else {
                        self.latitude = pin.latitude
                        self.longitude = pin.longitude
                    }
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
    
    func startLoadingImage(_ handler: @escaping (_ image : UIImage?, _ error: String?) -> Void) {
        if let urlString = imageURL, let urlFormat = URL(string: urlString) {
            task = URLSession.shared.dataTask(with: URLRequest(url: urlFormat), completionHandler: { (data, response, downloadError) in
                DispatchQueue.main.sync(execute: {
                    guard downloadError == nil else {
                        return handler(nil, "Business download error")
                    }
                    
                    guard let data = data, let image = UIImage(data: data) else {
                        return handler(nil, "Business data not correct")
                    }
                    
                    self.imageData = UIImageJPEGRepresentation(image, 0.0)
                    return handler(image, nil)
                })
            }) 
            task?.resume()
        } else {
            return handler(nil, "Business no image URL")
        }
    }
}
