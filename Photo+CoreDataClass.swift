//
//  Photo+CoreDataClass.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 12/4/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Photo)
public class Photo: NSManagedObject {
    
    lazy var filePath: String = {
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!.URLByAppendingPathComponent("image-\(self.id).jpg")!.path!
    } ()

    var task: NSURLSessionTask? = nil

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(id: String, url: String, pin: Pin, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) {
            super.init(entity: entity, insertIntoManagedObjectContext: context)
            
            self.id = id
            self.url = url
            self.pin = pin
            startLoadingImage(){ _ in }
        } else {
            fatalError("Unable to find Entity name with Photo!")
        }
    }
    
    // create image url with pin
    init(flickrDictionary: [String: AnyObject], pin: Pin, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) {
            super.init(entity: entity, insertIntoManagedObjectContext: context)
            
            self.id = flickrDictionary["id"] as? String
            self.url = flickrDictionary[FlickrClientAPI.FlickrParamsValue.URL_M] as? String
            startLoadingImage(){ _ in }
            self.pin = pin
        } else {
            fatalError("Unable to find Entity name with Photo!")
        }
    }
    
    func startLoadingImage(handler: (image : UIImage?, error: String?) -> Void) {
        cancelRequestLoadingImage()
        if let urlString = url, urlFormart = NSURL(string: urlString) {
            task = NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: urlFormart)) { (data, response, downloadError) in
                dispatch_async(dispatch_get_main_queue(), {
                    guard downloadError == nil else {
                        return handler(image: nil, error: "Photo download error")
                    }
                    
                    guard let data = data, let image = UIImage(data: data) else {
                        return handler(image: nil, error: "Photo data not correct")
                    }

                    self.photoImage = UIImageJPEGRepresentation(image, 0.0)
                    return handler(image: image, error: nil)
                })
            }
            task?.resume()
        }
    }
    
    func cancelRequestLoadingImage() {
        task?.cancel()
    }
}
