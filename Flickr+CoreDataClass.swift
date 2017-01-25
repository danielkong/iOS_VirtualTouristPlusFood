//
//  Flickr+CoreDataClass.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 12/4/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import Foundation
import CoreData

@objc(Flickr)
open class Flickr: NSManagedObject {
    
    var isLoading = false
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(nextPage: Int32 = 1, totalPages: Int32 = 1, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Flickr", in: context) {
            super.init(entity: entity, insertInto: context)
            self.nextPage = nextPage
            self.totalPages = totalPages
        } else {
            fatalError("Unable to find Entity name with Flickr!")
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    func loadNewPhotosAndAddToPin(_ context: NSManagedObjectContext, handler: @escaping (_ error: String?) -> Void) {
        if isLoading {
            return handler("Photos are Loading ...")
        }
        isLoading = true
        FlickrClientAPI.shared.loadPhotosWithCoordinate(Double(pin!.latitude), longitude: Double(pin!.longitude), page: Int(nextPage)) { (photos, pages, error) -> Void in
            DispatchQueue.main.async(execute: {
                guard error == nil else {
                    return handler(error)
                }
                
                // add to core data
                for photo in photos! {
                    if photo[FlickrClientAPI.FlickrParamsValue.URL_M] != nil {
                        _ = Photo(flickrDictionary: photo, pin: self.pin!, context: context)
                    }
                }
                self.totalPages = Int32(min(10, pages))
                self.nextPage = Int32(self.totalPages < (self.nextPage + 1) ? 1 : self.nextPage + 1)
                self.isLoading = false
                return handler(nil)
            })
        }
    }
}
