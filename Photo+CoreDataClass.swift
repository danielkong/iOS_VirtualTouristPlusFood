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
open class Photo: NSManagedObject {
    
    lazy var filePath: String = {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-\(self.id).jpg").path
    } ()

    var task: URLSessionTask? = nil

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(id: String, url: String, pin: Pin, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            super.init(entity: entity, insertInto: context)
            
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
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            super.init(entity: entity, insertInto: context)
            
            self.id = flickrDictionary["id"] as? String
            self.url = flickrDictionary[FlickrClientAPI.FlickrParamsValue.URL_M] as? String
            startLoadingImage(){ _ in }
            self.pin = pin
        } else {
            fatalError("Unable to find Entity name with Photo!")
        }
    }
    
    func startLoadingImage(_ handler: @escaping (_ image : UIImage?, _ error: String?) -> Void) {
        cancelRequestLoadingImage()
        if let urlString = url, let urlFormart = URL(string: urlString) {
            task = URLSession.shared.dataTask(with: URLRequest(url: urlFormart), completionHandler: { (data, response, downloadError) in
                DispatchQueue.main.async(execute: {
                    guard downloadError == nil else {
                        return handler(nil, "Photo download error")
                    }
                    
                    guard let data = data, let image = UIImage(data: data) else {
                        return handler(nil, "Photo data not correct")
                    }

                    self.photoImage = UIImageJPEGRepresentation(image, 0.0)
                    return handler(image, nil)
                })
            }) 
            task?.resume()
        }
    }
    
    func cancelRequestLoadingImage() {
        task?.cancel()
    }
}
