//
//  Pin+CoreDataProperties.swift
//  virtualTourist_dkong2
//
//  Created by Daniel Kong on 12/4/16.
//  Copyright © 2016 Daniel Kong. All rights reserved.
//

import Foundation
import CoreData


extension Pin {

    @nonobjc open override class func fetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
        return NSFetchRequest(entityName: "Pin");
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var flickr: Flickr?
    @NSManaged public var photos: [Photo]?
    @NSManaged public var businesses: [Business]?

}

// MARK: Generated accessors for photos
extension Pin {

    @objc(addPhotosObject:)
    @NSManaged public func addToPhotos(_ value: Photo)

    @objc(removePhotosObject:)
    @NSManaged public func removeFromPhotos(_ value: Photo)

    @objc(addPhotos:)
    @NSManaged public func addToPhotos(_ values: NSSet)

    @objc(removePhotos:)
    @NSManaged public func removeFromPhotos(_ values: NSSet)

}
